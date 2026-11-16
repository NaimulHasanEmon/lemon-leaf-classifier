import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Calibration disclosure', () {
    late Map<String, dynamic> modelCard;
    late Map<String, dynamic> thresholds;

    setUpAll(() {
      modelCard = json.decode(
        File('assets/config/model_card.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      thresholds = json.decode(
        File('assets/config/thresholds.json').readAsStringSync(),
      ) as Map<String, dynamic>;
    });

    test('Model card documents raw, uncalibrated softmax', () {
      final note = modelCard['calibration_note'] as String;
      expect(note.toLowerCase(), contains('without temperature scaling'));
      expect(note.toLowerCase(), contains('not a calibrated probability'));
    });

    test('No temperature scaling parameter is configured', () {
      expect(thresholds.containsKey('temperature'), isFalse);
      expect(thresholds.containsKey('calibration'), isFalse);
    });

    test('Abstention metadata states temperature scaling was not applied', () {
      final abstention =
          modelCard['abstention_thresholds'] as Map<String, dynamic>;
      final note = (abstention['note'] as String).toLowerCase();
      expect(note, contains('not applied'));
      expect(note, contains('temperature'));
    });
  });
}
