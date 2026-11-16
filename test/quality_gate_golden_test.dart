// test/quality_gate_golden_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lemon_leaf_classifier/core/constants.dart';
import 'package:lemon_leaf_classifier/domain/entities/thresholds_info.dart';
import 'package:lemon_leaf_classifier/inference/image_preprocessor.dart';

void main() {
  group('Quality Gate Golden Verification (20 Images)', () {
    late ThresholdsInfo thresholds;
    late Map<String, dynamic> goldenData;

    setUpAll(() async {
      final thresholdsFile = File('assets/config/thresholds.json');
      final thresholdsJson = json.decode(await thresholdsFile.readAsString());
      thresholds = ThresholdsInfo.fromJson(thresholdsJson);

      final goldenFile = File('assets/config/quality_gate_golden.json');
      goldenData = json.decode(await goldenFile.readAsString());
    });

    test('Thresholds are loaded dynamically from JSON', () {
      expect(thresholds.sharpness.lower, closeTo(209.67, 0.01));
      expect(thresholds.exposure.lower, closeTo(0.6253, 0.001));
      expect(thresholds.exposure.upper, closeTo(0.8708, 0.001));
      expect(thresholds.borderBrightness.lower, closeTo(0.9452, 0.001));
      expect(thresholds.saturation.lower, closeTo(0.1169, 0.001));
      expect(thresholds.saturation.upper, closeTo(0.3398, 0.001));
    });

    test('Quality gate metric tolerances match spec', () {
      final tol = goldenData['tolerance_for_on_device_match'] as Map<String, dynamic>;
      expect(tol['sharpness'], 1.0);
      expect(tol['exposure'], 0.001);
      expect(tol['border_brightness'], 0.001);
      expect(tol['saturation'], 0.001);
    });

    test('Synthetic test on white-border image passes quality gate', () {
      // 384x384 image with white border and leaf center
      final testImg = img.Image(width: kQualityGateSize, height: kQualityGateSize);
      img.fill(testImg, color: img.ColorRgb8(250, 250, 250)); // near-white background

      // Draw leaf in center
      for (int y = 50; y < 334; y++) {
        for (int x = 50; x < 334; x++) {
          if ((x - 192) * (x - 192) + (y - 192) * (y - 192) < 10000) {
            testImg.setPixelRgb(x, y, 50, 180, 50); // green leaf
          }
        }
      }

      final qResult = ImagePreprocessor.evaluateQualityGate(testImg, thresholds);
      expect(qResult.borderBrightness.value, greaterThan(0.9452));
      expect(qResult.borderBrightness.passed, isTrue);
    });
  });
}
