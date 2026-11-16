/// Numerically stable softmax used by the deployed inference pipeline.
import 'dart:math' as math;

List<double> softmaxProbabilities(List<double> logits) {
  if (logits.isEmpty) {
    throw ArgumentError.value(logits, 'logits', 'Must not be empty.');
  }
  if (logits.any((value) => !value.isFinite)) {
    throw ArgumentError.value(logits, 'logits', 'All logits must be finite.');
  }

  final maxValue = logits.reduce(math.max);
  final exponentials =
      logits.map((value) => math.exp(value - maxValue)).toList();
  final sum = exponentials.reduce((a, b) => a + b);
  return exponentials.map((value) => value / sum).toList();
}
