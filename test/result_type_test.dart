import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_leaf_classifier/domain/entities/classification_result.dart';
import 'package:lemon_leaf_classifier/domain/entities/quality_gate_result.dart';

void main() {
  QualityGateResult gate({required bool passed}) {
    return QualityGateResult(
      passed: passed,
      sharpness: QualityMetricCheck(
        name: 'Sharpness',
        value: passed ? 500 : 50,
        lowerBound: 209,
        upperBound: null,
        passed: passed,
        failureMessage: passed ? '' : 'Too blurry',
      ),
      exposure: QualityMetricCheck(
        name: 'Exposure', value: 0.75, lowerBound: 0.625,
        upperBound: 0.871, passed: true, failureMessage: '',
      ),
      borderBrightness: QualityMetricCheck(
        name: 'Border', value: 0.98, lowerBound: 0.945,
        upperBound: null, passed: true, failureMessage: '',
      ),
      saturation: QualityMetricCheck(
        name: 'Saturation', value: 0.22, lowerBound: 0.117,
        upperBound: 0.340, passed: true, failureMessage: '',
      ),
      failureReasons: passed ? [] : ['Too blurry'],
    );
  }

  final prediction = ClassPrediction(
    classLabel: 'citrus_leafminer',
    displayName: 'Citrus Leafminer',
    probability: 0.85,
    logit: 4.0,
  );

  group('ClassificationResult status mapping', () {
    test('Quality rejection is distinct from abstention and acceptance', () {
      final result = ClassificationResult(
        status: ClassificationStatus.qualityRejected,
        allPredictions: const [],
        qualityGateResult: gate(passed: false),
        statusReason: 'Image quality rejected.',
      );
      expect(result.isQualityRejected, isTrue);
      expect(result.isAbstained, isFalse);
      expect(result.isAccepted, isFalse);
      expect(result.topPrediction, isNull);
    });

    test('Abstained result retains predictions but is not accepted', () {
      final result = ClassificationResult(
        status: ClassificationStatus.abstained,
        topPrediction: prediction,
        allPredictions: [prediction],
        qualityGateResult: gate(passed: true),
        statusReason: 'Prediction is uncertain.',
        maxProbability: 0.40,
        margin: 0.05,
      );
      expect(result.isAbstained, isTrue);
      expect(result.isAccepted, isFalse);
      expect(result.isQualityRejected, isFalse);
    });

    test('Accepted result has accepted status and prediction', () {
      final result = ClassificationResult(
        status: ClassificationStatus.accepted,
        topPrediction: prediction,
        allPredictions: [prediction],
        qualityGateResult: gate(passed: true),
        statusReason: 'Classification accepted.',
        maxProbability: 0.85,
        margin: 0.60,
      );
      expect(result.isAccepted, isTrue);
      expect(result.isAbstained, isFalse);
      expect(result.isQualityRejected, isFalse);
    });

    test('Top-three predictions are sorted by probability', () {
      final lower = ClassPrediction(
        classLabel: 'citrus_leaf_curl',
        displayName: 'Citrus Leaf Curl',
        probability: 0.10,
        logit: -1.0,
      );
      final middle = ClassPrediction(
        classLabel: 'healthy_lemon_leaf',
        displayName: 'Healthy Lemon Leaf',
        probability: 0.30,
        logit: 1.0,
      );
      final result = ClassificationResult(
        status: ClassificationStatus.accepted,
        topPrediction: prediction,
        allPredictions: [lower, prediction, middle],
        qualityGateResult: gate(passed: true),
        statusReason: 'Accepted.',
      );
      expect(result.top3Predictions.map((p) => p.classLabel).toList(), [
        'citrus_leafminer',
        'healthy_lemon_leaf',
        'citrus_leaf_curl',
      ]);
    });
  });
}
