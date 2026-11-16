// lib/domain/entities/model_card_info.dart

class DeployedMetrics {
  final double accuracy;
  final double balancedAccuracy;
  final double macroF1;
  final double logLoss;
  final Map<String, double> perClassRecall;
  final String uncertaintyNote;

  const DeployedMetrics({
    required this.accuracy,
    required this.balancedAccuracy,
    required this.macroF1,
    required this.logLoss,
    required this.perClassRecall,
    required this.uncertaintyNote,
  });

  factory DeployedMetrics.fromJson(Map<String, dynamic> json) {
    final recallMap = (json['per_class_recall'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    return DeployedMetrics(
      accuracy: (json['accuracy'] as num).toDouble(),
      balancedAccuracy: (json['balanced_accuracy'] as num).toDouble(),
      macroF1: (json['macro_f1'] as num).toDouble(),
      logLoss: (json['log_loss'] as num).toDouble(),
      perClassRecall: recallMap,
      uncertaintyNote: json['uncertainty_note'] ?? '',
    );
  }
}

class AbstentionRules {
  final double tau;
  final double delta;
  final double selectiveAccuracy;
  final double coverage;

  const AbstentionRules({
    required this.tau,
    required this.delta,
    required this.selectiveAccuracy,
    required this.coverage,
  });

  factory AbstentionRules.fromJson(Map<String, dynamic> json) {
    return AbstentionRules(
      tau: (json['tau_max_softmax'] as num).toDouble(),
      delta: (json['delta_top1_top2'] as num).toDouble(),
      selectiveAccuracy: (json['resulting_selective_accuracy'] as num).toDouble(),
      coverage: (json['resulting_coverage'] as num).toDouble(),
    );
  }
}

class ModelCardInfo {
  final String modelName;
  final String modelVersion;
  final String modelArchitecture;
  final int inputResolution;
  final String intendedUse;
  final List<String> outOfScopeUse;
  final DeployedMetrics deployedMetrics;
  final AbstentionRules abstentionRules;
  final String externalValidationFailureSummary;
  final String externalAccuracyRange;

  const ModelCardInfo({
    required this.modelName,
    required this.modelVersion,
    required this.modelArchitecture,
    required this.inputResolution,
    required this.intendedUse,
    required this.outOfScopeUse,
    required this.deployedMetrics,
    required this.abstentionRules,
    required this.externalValidationFailureSummary,
    required this.externalAccuracyRange,
  });

  factory ModelCardInfo.fromJson(Map<String, dynamic> json) {
    final extFail = json['external_validation_failure'] as Map<String, dynamic>? ?? {};
    final outOfScope = (json['out_of_scope_use'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return ModelCardInfo(
      modelName: json['model_name'] ?? 'ConvNeXt-Tiny Lemon Leaf Classifier',
      modelVersion: json['model_version'] ?? '1.0.0',
      modelArchitecture: json['model_architecture'] ?? 'convnext_tiny (timm)',
      inputResolution: json['input_resolution'] ?? 320,
      intendedUse: json['intended_use'] ?? '',
      outOfScopeUse: outOfScope,
      deployedMetrics: DeployedMetrics.fromJson(json['deployed_model_metrics'] as Map<String, dynamic>),
      abstentionRules: AbstentionRules.fromJson(json['abstention_thresholds'] as Map<String, dynamic>),
      externalValidationFailureSummary: extFail['summary'] ?? '',
      externalAccuracyRange: extFail['external_accuracy_range'] ?? '0.47 to 0.68',
    );
  }
}

