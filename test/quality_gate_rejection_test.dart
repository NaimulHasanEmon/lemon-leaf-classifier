// test/quality_gate_rejection_test.dart
//
// Verifies the quality gate rejects images that fail the configured checks,
// without changing the gate logic or thresholds (loaded from thresholds.json).
// Synthetic 384x384 images exercise each rejection path:
//   - dark image -> exposure lower bound
//   - non-white background -> border brightness lower bound
//   - oversaturated image -> saturation upper bound
// A passing white-border image is used as a control.
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lemon_leaf_classifier/core/constants.dart';
import 'package:lemon_leaf_classifier/domain/entities/thresholds_info.dart';
import 'package:lemon_leaf_classifier/inference/image_preprocessor.dart';

void main() {
  late ThresholdsInfo thresholds;

  setUpAll(() async {
    final thresholdsJson =
        json.decode(File('assets/config/thresholds.json').readAsStringSync())
            as Map<String, dynamic>;
    thresholds = ThresholdsInfo.fromJson(thresholdsJson);
  });

  img.Image whiteBorderLeaf({int leaf = 50, int bg = 250}) {
    final image = img.Image(width: kQualityGateSize, height: kQualityGateSize);
    img.fill(image, color: img.ColorRgb8(bg, bg, bg));
    for (int y = 60; y < 324; y++) {
      for (int x = 60; x < 324; x++) {
        if ((x - 192) * (x - 192) + (y - 192) * (y - 192) < 10000) {
          image.setPixelRgb(x, y, leaf, 180, leaf);
        }
      }
    }
    return image;
  }

  group('Quality gate rejection paths', () {
    test('White-border leaf image PASSES the gate', () {
      final q = ImagePreprocessor.evaluateQualityGate(
          whiteBorderLeaf(), thresholds);
      expect(q.passed, isTrue, reason: q.failureReasons.join('\n'));
    });

    test('Dark image is REJECTED (exposure < lower bound)', () {
      final dark = img.Image(width: kQualityGateSize, height: kQualityGateSize);
      img.fill(dark, color: img.ColorRgb8(20, 20, 20));
      final q = ImagePreprocessor.evaluateQualityGate(dark, thresholds);
      expect(q.passed, isFalse);
      expect(q.exposure.passed, isFalse);
      expect(q.failureReasons, isNotEmpty);
    });

    test('Non-white (dark) background is REJECTED (border brightness)', () {
      // A green image filling the whole frame, including the border.
      final green = img.Image(width: kQualityGateSize, height: kQualityGateSize);
      img.fill(green, color: img.ColorRgb8(40, 140, 40));
      final q = ImagePreprocessor.evaluateQualityGate(green, thresholds);
      expect(q.borderBrightness.passed, isFalse,
          reason: 'borderBrightness=${q.borderBrightness.value}');
      expect(q.passed, isFalse);
    });

    test('Pure red image is REJECTED (border brightness + saturation)', () {
      final red = img.Image(width: kQualityGateSize, height: kQualityGateSize);
      img.fill(red, color: img.ColorRgb8(255, 0, 0));
      final q = ImagePreprocessor.evaluateQualityGate(red, thresholds);
      expect(q.passed, isFalse);
    });
  });
}
