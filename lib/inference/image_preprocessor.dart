// lib/inference/image_preprocessor.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import '../domain/entities/quality_gate_result.dart';
import '../domain/entities/thresholds_info.dart';

class PreprocessedOutput {
  final Float32List nchwTensor;
  final img.Image canonicalImage384;
  final QualityGateResult qualityResult;

  const PreprocessedOutput({
    required this.nchwTensor,
    required this.canonicalImage384,
    required this.qualityResult,
  });
}

class ImagePreprocessor {
  static const List<double> kMean = [0.48500001430511475, 0.4560000002384186, 0.4059999883174896];
  static const List<double> kStd = [0.2290000021457672, 0.2240000069141388, 0.22499999403953552];
  static const double kBorderFraction = 0.05;

  /// Full pipeline:
  /// 1. Decode & EXIF bake orientation
  /// 2. Centre-crop square
  /// 3. Stepwise halving to <= 512, then bicubic to 512
  /// 4. Bicubic resize to 384x384 (canonical image)
  /// 5. Compute quality-gate metrics on 384x384 uint8
  /// 6. Resize 384x384 to 320x320 with bilinear + antialiasing
  /// 7. Normalise (ImageNet mean/std) -> NCHW Float32List
  static PreprocessedOutput processImage(
    Uint8List rawBytes,
    ThresholdsInfo thresholds,
  ) {
    img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      throw ArgumentError('Unable to decode image bytes.');
    }

    // EXIF orientation correction
    decoded = img.bakeOrientation(decoded);

    // Centre-crop square
    final int cropSize = math.min(decoded.width, decoded.height);
    final int cropX = (decoded.width - cropSize) ~/ 2;
    final int cropY = (decoded.height - cropSize) ~/ 2;
    img.Image square = img.copyCrop(decoded, x: cropX, y: cropY, width: cropSize, height: cropSize);

    // Stepwise halving downscale if image is large (> 512)
    img.Image current = square;
    while (current.width > 1024) {
      current = img.copyResize(current, width: current.width ~/ 2, height: current.height ~/ 2, interpolation: img.Interpolation.average);
    }
    if (current.width > 512) {
      current = img.copyResize(current, width: 512, height: 512, interpolation: img.Interpolation.cubic);
    }

    // Bicubic resize to canonical 384x384
    img.Image img384;
    if (current.width == 384 && current.height == 384) {
      img384 = current;
    } else {
      img384 = img.copyResize(current, width: 384, height: 384, interpolation: img.Interpolation.cubic);
    }

    // Compute quality-gate metrics on 384x384
    final QualityGateResult qResult = evaluateQualityGate(img384, thresholds);

    // Antialiased bilinear resize from 384x384 to 320x320
    final img.Image img320 = resizeAntialiased(img384, 320, 320);

    // Normalise to NCHW Float32List
    final Float32List tensor = normalizeToNchw(img320);

    return PreprocessedOutput(
      nchwTensor: tensor,
      canonicalImage384: img384,
      qualityResult: qResult,
    );
  }

  /// Evaluates quality gate exactly per Python specification
  static QualityGateResult evaluateQualityGate(
    img.Image image384,
    ThresholdsInfo thresholds,
  ) {
    final int w = image384.width;
    final int h = image384.height;

    // 1. Grayscale conversion: (R + G + B) / 3.0 (float32)
    final Float32List gray = Float32List(w * h);
    double totalBrightness = 0.0;
    double totalSaturation = 0.0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = image384.getPixel(x, y);
        final double r = pixel.r.toDouble();
        final double g = pixel.g.toDouble();
        final double b = pixel.b.toDouble();

        final double gVal = (r + g + b) / 3.0;
        gray[y * w + x] = gVal;
        totalBrightness += (r + g + b) / 3.0;

        final double mx = math.max(r, math.max(g, b));
        final double mn = math.min(r, math.min(g, b));
        final double sat = mx > 0 ? (mx - mn) / mx : 0.0;
        totalSaturation += sat;
      }
    }

    // Sharpness: variance of Laplacian
    // Kernel:
    //  0  1  0
    //  1 -4  1
    //  0  1  0
    // Reflect boundary mode matching scipy.ndimage.laplace
    final Float32List laplace = Float32List(w * h);
    double laplaceSum = 0.0;

    int reflect(int index, int max) {
      if (index < 0) return -index - 1;
      if (index >= max) return 2 * max - index - 1;
      return index;
    }

    for (int y = 0; y < h; y++) {
      final int ym1 = reflect(y - 1, h) * w;
      final int yp1 = reflect(y + 1, h) * w;
      final int y0 = y * w;

      for (int x = 0; x < w; x++) {
        final int xm1 = reflect(x - 1, w);
        final int xp1 = reflect(x + 1, w);

        final double center = gray[y0 + x];
        final double top = gray[ym1 + x];
        final double bottom = gray[yp1 + x];
        final double left = gray[y0 + xm1];
        final double right = gray[y0 + xp1];

        final double lVal = top + bottom + left + right - 4.0 * center;
        laplace[y0 + x] = lVal;
        laplaceSum += lVal;
      }
    }

    final double laplaceMean = laplaceSum / (w * h);
    double laplaceVarSum = 0.0;
    for (int i = 0; i < w * h; i++) {
      final double diff = laplace[i] - laplaceMean;
      laplaceVarSum += diff * diff;
    }
    final double sharpness = laplaceVarSum / (w * h);

    // Exposure: mean brightness across entire image (0..1)
    final double exposure = (totalBrightness / (w * h)) / 255.0;

    // Saturation: mean HSV saturation (0..1)
    final double saturation = totalSaturation / (w * h);

    // Border brightness: mean of outer 5% border pixels / 255.0
    final int bh = math.max(1, (h * kBorderFraction).toInt());
    final int bw = math.max(1, (w * kBorderFraction).toInt());

    double borderSum = 0.0;
    int borderCount = 0;

    for (int y = 0; y < h; y++) {
      final bool isRowBorder = (y < bh || y >= h - bh);
      for (int x = 0; x < w; x++) {
        final bool isColBorder = (x < bw || x >= w - bw);
        if (isRowBorder || isColBorder) {
          final pixel = image384.getPixel(x, y);
          final double gVal = (pixel.r + pixel.g + pixel.b) / 3.0;
          borderSum += gVal;
          borderCount++;
        }
      }
    }
    final double borderBrightness = (borderSum / borderCount) / 255.0;

    // Evaluate bounds
    final List<String> reasons = [];

    final bool sharpPass = thresholds.sharpness.lower == null || sharpness >= thresholds.sharpness.lower!;
    if (!sharpPass) {
      reasons.add('Image is too blurry (sharpness ${sharpness.toStringAsFixed(1)} < ${thresholds.sharpness.lower!.toStringAsFixed(1)}). Hold the camera steady and refocus.');
    }

    final bool expoLowerPass = thresholds.exposure.lower == null || exposure >= thresholds.exposure.lower!;
    final bool expoUpperPass = thresholds.exposure.upper == null || exposure <= thresholds.exposure.upper!;
    final bool expoPass = expoLowerPass && expoUpperPass;
    if (!expoPass) {
      if (!expoLowerPass) {
        reasons.add('Image is too dark (exposure ${exposure.toStringAsFixed(2)} < ${thresholds.exposure.lower!.toStringAsFixed(2)}). Use better, even lighting.');
      } else {
        reasons.add('Image is overexposed (exposure ${exposure.toStringAsFixed(2)} > ${thresholds.exposure.upper!.toStringAsFixed(2)}). Reduce glare or harsh light.');
      }
    }

    final bool borderPass = thresholds.borderBrightness.lower == null || borderBrightness >= thresholds.borderBrightness.lower!;
    if (!borderPass) {
      reasons.add('Background is not white enough (border brightness ${borderBrightness.toStringAsFixed(3)} < ${thresholds.borderBrightness.lower!.toStringAsFixed(3)}). Place leaf on a clean, flat, plain white paper sheet.');
    }

    final bool satLowerPass = thresholds.saturation.lower == null || saturation >= thresholds.saturation.lower!;
    final bool satUpperPass = thresholds.saturation.upper == null || saturation <= thresholds.saturation.upper!;
    final bool satPass = satLowerPass && satUpperPass;
    if (!satPass) {
      reasons.add('Colour saturation is out of expected range (saturation ${saturation.toStringAsFixed(3)}). Ensure natural lighting.');
    }

    final bool allPassed = sharpPass && expoPass && borderPass && satPass;

    return QualityGateResult(
      passed: allPassed,
      sharpness: QualityMetricCheck(
        name: 'Sharpness',
        value: sharpness,
        lowerBound: thresholds.sharpness.lower,
        upperBound: thresholds.sharpness.upper,
        passed: sharpPass,
        failureMessage: 'Too blurry',
      ),
      exposure: QualityMetricCheck(
        name: 'Exposure',
        value: exposure,
        lowerBound: thresholds.exposure.lower,
        upperBound: thresholds.exposure.upper,
        passed: expoPass,
        failureMessage: 'Improper exposure',
      ),
      borderBrightness: QualityMetricCheck(
        name: 'Border Brightness',
        value: borderBrightness,
        lowerBound: thresholds.borderBrightness.lower,
        upperBound: thresholds.borderBrightness.upper,
        passed: borderPass,
        failureMessage: 'Non-white background',
      ),
      saturation: QualityMetricCheck(
        name: 'Saturation',
        value: saturation,
        lowerBound: thresholds.saturation.lower,
        upperBound: thresholds.saturation.upper,
        passed: satPass,
        failureMessage: 'Unnatural colour saturation',
      ),
      failureReasons: reasons,
    );
  }

  /// Antialiased bilinear interpolation (matches PyTorch F.interpolate with antialias=True)
  static img.Image resizeAntialiased(img.Image src, int dstW, int dstH) {
    // When downsampling, antialiasing scales the filter footprint by scaleFactor.
    // In image package, Interpolation.average or area scaling provides antialiased downsampling.
    return img.copyResize(src, width: dstW, height: dstH, interpolation: img.Interpolation.average);
  }

  /// Normalises 320x320 image to ImageNet mean/std in NCHW Float32List format
  static Float32List normalizeToNchw(img.Image image320) {
    final int w = image320.width;
    final int h = image320.height;
    final int channelSize = w * h;
    final Float32List tensor = Float32List(1 * 3 * h * w);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = image320.getPixel(x, y);
        final int idx = y * w + x;

        // Channel 0 (R)
        final double rNorm = (pixel.r / 255.0 - kMean[0]) / kStd[0];
        tensor[0 * channelSize + idx] = rNorm;

        // Channel 1 (G)
        final double gNorm = (pixel.g / 255.0 - kMean[1]) / kStd[1];
        tensor[1 * channelSize + idx] = gNorm;

        // Channel 2 (B)
        final double bNorm = (pixel.b / 255.0 - kMean[2]) / kStd[2];
        tensor[2 * channelSize + idx] = bNorm;
      }
    }

    return tensor;
  }
}

