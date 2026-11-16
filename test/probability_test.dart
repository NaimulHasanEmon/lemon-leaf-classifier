import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_leaf_classifier/core/constants.dart';
import 'package:lemon_leaf_classifier/inference/softmax.dart';

void main() {
  group('Production softmax probability calculation', () {
    test('Probabilities sum to one', () {
      final probs = softmaxProbabilities([2.4, -0.5, -1.6, -1.5, 0.96]);
      expect(probs.reduce((a, b) => a + b), closeTo(1.0, 1e-9));
    });

    test('Every probability is in [0, 1]', () {
      final probs = softmaxProbabilities([4.0, 1.0, 0.5, -1.0, 0.0]);
      for (final probability in probs) {
        expect(probability, inInclusiveRange(0.0, 1.0));
      }
    });

    test('Argmax of probabilities matches argmax of logits', () {
      final logits = [2.4, -0.5, -1.6, -1.5, 0.96];
      final probs = softmaxProbabilities(logits);
      final logitArgmax = logits.indexOf(logits.reduce((a, b) => a > b ? a : b));
      final probabilityArgmax =
          probs.indexOf(probs.reduce((a, b) => a > b ? a : b));
      expect(probabilityArgmax, logitArgmax);
    });

    test('Sorted probabilities preserve class labels', () {
      final probs = softmaxProbabilities([2.4, -0.5, -1.6, -1.5, 0.96]);
      final indexed =
          List.generate(kClassLabels.length, (i) => MapEntry(kClassLabels[i], probs[i]));
      indexed.sort((a, b) => b.value.compareTo(a.value));
      expect(indexed.first.key, kClassLabels[0]);
      expect(indexed.map((entry) => entry.key).toSet().length, 5);
    });

    test('Uniform logits produce equal probabilities', () {
      final probs = softmaxProbabilities([1.0, 1.0, 1.0, 1.0, 1.0]);
      for (final probability in probs) {
        expect(probability, closeTo(0.2, 1e-9));
      }
    });

    test('Rejects empty and non-finite logits', () {
      expect(() => softmaxProbabilities([]), throwsArgumentError);
      expect(() => softmaxProbabilities([1, double.nan]), throwsArgumentError);
    });
  });
}
