import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_leaf_classifier/core/constants.dart';

void main() {
  group('Class-index mapping', () {
    test('There are exactly five classes in model output order', () {
      expect(kClassLabels, [
        'citrus_huanglongbing',
        'citrus_leaf_curl',
        'citrus_leafminer',
        'healthy_lemon_leaf',
        'swallowtail_herbivory',
      ]);
    });

    test('Every class has English and Bangla display names', () {
      for (final label in kClassLabels) {
        expect(kClassDisplayNames[label], isNotNull);
        expect(kClassDisplayNames[label]!.isNotEmpty, isTrue);
        expect(kClassDisplayNamesBn[label], isNotNull);
        expect(kClassDisplayNamesBn[label]!.isNotEmpty, isTrue);
      }
    });

    test('HLB identifier points to output index zero', () {
      expect(kHlbClassLabel, 'citrus_huanglongbing');
      expect(kClassLabels.indexOf(kHlbClassLabel), 0);
    });

    test('Golden logits class order matches application constants', () {
      final golden = json.decode(
        File('assets/parity/golden_logits.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect((golden['classes'] as List<dynamic>).cast<String>(), kClassLabels);
    });

    test('Model card class order matches application constants', () {
      final card = json.decode(
        File('assets/config/model_card.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect((card['classes'] as List<dynamic>).cast<String>(), kClassLabels);
    });
  });
}
