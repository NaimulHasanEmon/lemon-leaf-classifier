// test/invalid_image_test.dart
//
// Verifies that invalid / undecodable image bytes are handled gracefully:
// the preprocessing pipeline throws an ArgumentError (not a crash), which the
// inference service maps to a ClassificationResult.error. This guards against
// garbage input being passed to the ONNX model.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
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

  group('Invalid image handling', () {
    test('Empty bytes throw ArgumentError', () {
      expect(
        () => ImagePreprocessor.processImage(Uint8List(0), thresholds),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Random non-image bytes throw ArgumentError', () {
      final garbage =
          Uint8List.fromList(List.generate(1024, (i) => (i * 37) % 256));
      expect(
        () => ImagePreprocessor.processImage(garbage, thresholds),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Truncated PNG bytes throw ArgumentError', () {
      // A real PNG header followed by truncation cannot be decoded.
      final truncated = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0, 0, 0, 13, // length
      ]);
      expect(
        () => ImagePreprocessor.processImage(truncated, thresholds),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('A valid PNG round-trips through processImage without throwing', () {
      // Generate a small valid PNG on the fly and confirm it is accepted.
      // (Use a plain white square so the gate result is deterministic.)
      final image = img.Image(width: 384, height: 384);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      final bytes = Uint8List.fromList(img.encodePng(image));
      expect(bytes, isNotEmpty);
      // processImage should NOT throw on valid bytes.
      final out = ImagePreprocessor.processImage(bytes, thresholds);
      expect(out.nchwTensor.length, 1 * 3 * 320 * 320);
    });
  });
}
