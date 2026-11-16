import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_leaf_classifier/core/constants.dart';

void main() {
  group('Preprocessing parity specification and release model metadata', () {
    const int numImages = 100;
    const int numClasses = 5;

    test('Golden logits contain 100 entries with five logits each', () async {
      final goldenFile = File('assets/parity/golden_logits.json');
      expect(await goldenFile.exists(), isTrue);
      final data = json.decode(await goldenFile.readAsString())
          as Map<String, dynamic>;
      final entries = (data['images'] ?? data['logits']) as List<dynamic>;
      expect(entries.length, numImages);
      for (final entry in entries) {
        expect(entry['filename'], isNotNull);
        final logits =
            (entry['reference_logits'] ?? entry['logits']) as List<dynamic>;
        expect(logits.length, numClasses);
      }
    });

    test('Exactly 100 parity PNGs are present', () async {
      final directory = Directory('assets/parity');
      expect(await directory.exists(), isTrue);
      final files = await directory
          .list()
          .where((file) => file.path.toLowerCase().endsWith('.png'))
          .toList();
      expect(files.length, numImages);
    });

    test('Required model configuration files exist', () async {
      expect(await File('assets/config/model_card.json').exists(), isTrue);
      expect(await File('assets/config/thresholds.json').exists(), isTrue);
      expect(
        await File('assets/config/quality_gate_golden.json').exists(),
        isTrue,
      );
    });

    test('App is configured for the FP32 ONNX model', () async {
      expect(
        kModelAssetPath,
        'assets/models/convnext_tiny_320_f2_fp32.onnx',
      );
      final pubspec = await File('pubspec.yaml').readAsString();
      expect(pubspec, contains(kModelAssetPath));
      expect(pubspec, isNot(contains('convnext_tiny_320_f2_fp16.onnx')));

      final modelCard = json.decode(
        await File('assets/config/model_card.json').readAsString(),
      ) as Map<String, dynamic>;
      final deployed =
          modelCard['deployed_model_metrics'] as Map<String, dynamic>;
      expect(deployed['variant'], 'fp32');
      expect(deployed['onnx_file'], 'convnext_tiny_320_f2_fp32.onnx');

      final evaluation = json.decode(
        await File('assets/config/eval_results.json').readAsString(),
      ) as Map<String, dynamic>;
      final identity = evaluation['model_identity'] as Map<String, dynamic>;
      expect(
        (deployed['onnx_sha256'] as String).toLowerCase(),
        (identity['onnx_fp32_sha256'] as String).toLowerCase(),
      );
    });

    test('Evaluation metadata identifies the same FP32 model', () async {
      final evaluation = json.decode(
        await File('assets/config/eval_results.json').readAsString(),
      ) as Map<String, dynamic>;
      final identity =
          evaluation['model_identity'] as Map<String, dynamic>;
      expect(identity['deployed_format'], 'FP32 ONNX (opset 17)');
      expect(identity['onnx_fp32_sha256'], isA<String>());
      expect((identity['onnx_fp32_sha256'] as String).length, 64);
    });
  });
}
