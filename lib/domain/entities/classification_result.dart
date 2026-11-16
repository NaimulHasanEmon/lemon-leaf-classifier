// lib/domain/entities/classification_result.dart
import 'dart:typed_data';
import 'quality_gate_result.dart';

enum ClassificationStatus {
  accepted,
  qualityRejected,
  abstained,
}

class ClassPrediction {
  final String classLabel;
  final String displayName;
  final double probability;
  final double logit;

  const ClassPrediction({
    required this.classLabel,
    required this.displayName,
    required this.probability,
    required this.logit,
  });
}

class ClassificationResult {
  final ClassificationStatus status;
  final ClassPrediction? topPrediction;
  final List<ClassPrediction> allPredictions;
  final QualityGateResult qualityGateResult;
  final String statusReason;
  final Uint8List? processedImageBytes;
  final double? maxProbability;
  final double? margin;

  const ClassificationResult({
    required this.status,
    this.topPrediction,
    required this.allPredictions,
    required this.qualityGateResult,
    required this.statusReason,
    this.processedImageBytes,
    this.maxProbability,
    this.margin,
  });

  bool get isAccepted => status == ClassificationStatus.accepted;
  bool get isQualityRejected => status == ClassificationStatus.qualityRejected;
  bool get isAbstained => status == ClassificationStatus.abstained;

  List<ClassPrediction> get top3Predictions {
    final sorted = List<ClassPrediction>.from(allPredictions)
      ..sort((a, b) => b.probability.compareTo(a.probability));
    return sorted.take(3).toList();
  }

  static const String cautionBannerText =
      'Research prototype for white-sheet photography only. Confidence is not a probability of correctness under different lighting or backgrounds. Symptoms overlap across citrus diseases; Huanglongbing (HLB) is only confirmed by laboratory testing (PCR).';
}

