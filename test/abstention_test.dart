// test/abstention_test.dart
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Abstention Decision Boundary Tests (tau=0.53, delta=0.24)', () {
    const double tau = 0.53;
    const double delta = 0.24;

    List<double> softmax(List<double> logits) {
      final double maxVal = logits.reduce(math.max);
      final List<double> exps = logits.map((v) => math.exp(v - maxVal)).toList();
      final double sum = exps.reduce((a, b) => a + b);
      return exps.map((v) => v / sum).toList();
    }

    bool shouldAbstain(List<double> probs) {
      final sorted = List<double>.from(probs)..sort((a, b) => b.compareTo(a));
      final double maxProb = sorted[0];
      final double margin = sorted[0] - sorted[1];
      return maxProb < tau || margin < delta;
    }

    test('Confident and separated prediction is ACCEPTED', () {
      final logits = [4.0, 1.0, 0.5, -1.0, 0.0];
      final probs = softmax(logits);
      // maxProb will be ~0.89, margin ~0.84 -> accepted
      expect(shouldAbstain(probs), isFalse);
    });

    test('Low max probability (< 0.53) ABSTAINS', () {
      // 5 nearly uniform classes
      final logits = [1.0, 0.9, 0.8, 0.85, 0.95];
      final probs = softmax(logits);
      expect(probs.reduce(math.max), lessThan(tau));
      expect(shouldAbstain(probs), isTrue);
    });

    test('High confidence but small margin (< 0.24) ABSTAINS', () {
      // Two very close high classes (e.g. 0.49 and 0.45 or 0.54 and 0.42)
      // If top1=0.54, top2=0.42 -> maxProb >= 0.53, but margin = 0.12 < 0.24
      final probs = [0.54, 0.42, 0.02, 0.01, 0.01];
      expect(shouldAbstain(probs), isTrue);
    });

    test('Boundary test: exact tau and delta thresholds', () {
      final probsAccepted = [0.55, 0.25, 0.10, 0.05, 0.05];
      // maxProb = 0.55 >= 0.53, margin = 0.30 >= 0.24
      expect(shouldAbstain(probsAccepted), isFalse);

      final probsMarginalReject = [0.53, 0.35, 0.05, 0.04, 0.03];
      // maxProb = 0.53 >= 0.53, but margin = 0.18 < 0.24
      expect(shouldAbstain(probsMarginalReject), isTrue);
    });
  });
}

