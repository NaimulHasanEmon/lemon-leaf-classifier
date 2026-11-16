// lib/domain/entities/quality_gate_result.dart

class QualityMetricCheck {
  final String name;
  final double value;
  final double? lowerBound;
  final double? upperBound;
  final bool passed;
  final String failureMessage;

  const QualityMetricCheck({
    required this.name,
    required this.value,
    this.lowerBound,
    this.upperBound,
    required this.passed,
    required this.failureMessage,
  });
}

class QualityGateResult {
  final bool passed;
  final QualityMetricCheck sharpness;
  final QualityMetricCheck exposure;
  final QualityMetricCheck borderBrightness;
  final QualityMetricCheck saturation;
  final List<String> failureReasons;

  const QualityGateResult({
    required this.passed,
    required this.sharpness,
    required this.exposure,
    required this.borderBrightness,
    required this.saturation,
    required this.failureReasons,
  });

  String get summaryAdvice {
    if (passed) return 'Photo meets quality requirements.';
    return failureReasons.join('\n');
  }
}

