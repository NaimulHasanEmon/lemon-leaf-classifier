// lib/inference/inference_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

import '../core/constants.dart';
import '../domain/entities/classification_result.dart';
import '../domain/entities/model_card_info.dart';
import '../domain/entities/quality_gate_result.dart';
import '../domain/entities/thresholds_info.dart';
import 'image_preprocessor.dart';
import 'softmax.dart';

abstract class InferenceService {
  Future<void> initialize();
  Future<ClassificationResult> classifyImage(Uint8List imageBytes, {bool skipQualityGate = false});
  Future<List<double>> runLogits(Float32List nchwTensor);
  void dispose();

  ModelCardInfo? get modelCard;
  ThresholdsInfo? get thresholds;
}

class OnnxRuntimeInferenceService implements InferenceService {
  final String modelAssetPath;
  final String modelCardAssetPath;
  final String thresholdsAssetPath;

  OrtSession? _session;
  ModelCardInfo? _modelCard;
  ThresholdsInfo? _thresholds;
  bool _isInitialized = false;

  OnnxRuntimeInferenceService({
    this.modelAssetPath = kModelAssetPath,
    this.modelCardAssetPath = kModelCardAssetPath,
    this.thresholdsAssetPath = kThresholdsAssetPath,
  });

  @override
  ModelCardInfo? get modelCard => _modelCard;

  @override
  ThresholdsInfo? get thresholds => _thresholds;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Load config JSONs
    final String modelCardStr = await rootBundle.loadString(modelCardAssetPath);
    _modelCard = ModelCardInfo.fromJson(json.decode(modelCardStr));

    final String thresholdsStr = await rootBundle.loadString(thresholdsAssetPath);
    _thresholds = ThresholdsInfo.fromJson(json.decode(thresholdsStr));

    // 2. Initialize ORT Environment
    OrtEnv.instance.init();

    // 3. Load ONNX model bytes from assets
    final ByteData modelData = await rootBundle.load(modelAssetPath);
    final Uint8List modelBytes = modelData.buffer.asUint8List(
      modelData.offsetInBytes,
      modelData.lengthInBytes,
    );

    // 4. Create Session with CPUExecutionProvider (single-threaded / CPU default)
    final sessionOptions = OrtSessionOptions();
    try {
      sessionOptions.setIntraOpNumThreads(2);
      _session = OrtSession.fromBuffer(modelBytes, sessionOptions);
    } finally {
      sessionOptions.release();
    }

    _isInitialized = true;
  }

  @override
  Future<ClassificationResult> classifyImage(
    Uint8List imageBytes, {
    bool skipQualityGate = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final ThresholdsInfo th = _thresholds!;
    final ModelCardInfo mc = _modelCard!;

    // Step A: Preprocess image & compute quality-gate metrics
    final PreprocessedOutput preprocessed = ImagePreprocessor.processImage(imageBytes, th);
    final QualityGateResult qResult = preprocessed.qualityResult;

    // If quality gate fails and not skipped, return immediately
    if (!qResult.passed && !skipQualityGate) {
      return ClassificationResult(
        status: ClassificationStatus.qualityRejected,
        allPredictions: const [],
        qualityGateResult: qResult,
        statusReason: qResult.summaryAdvice,
      );
    }

    // Step B: Run model inference to get raw logits
    final List<double> logits = await runLogits(preprocessed.nchwTensor);

    // Step C: Compute raw softmax probabilities (no temperature scaling)
    final List<double> probs = softmaxProbabilities(logits);

    // Map to ClassPrediction objects
    final List<ClassPrediction> predictions = [];
    for (int i = 0; i < kClassLabels.length; i++) {
      final String label = kClassLabels[i];
      final String dName = kClassDisplayNames[label] ?? label;
      predictions.add(ClassPrediction(
        classLabel: label,
        displayName: dName,
        probability: probs[i],
        logit: logits[i],
      ));
    }

    // Sort to determine top-1 and top-2
    final sorted = List<ClassPrediction>.from(predictions)
      ..sort((a, b) => b.probability.compareTo(a.probability));

    final ClassPrediction top1 = sorted[0];
    final ClassPrediction top2 = sorted.length > 1 ? sorted[1] : sorted[0];

    final double maxProb = top1.probability;
    final double margin = maxProb - top2.probability;

    // Step D: Apply abstention rule (tau, delta)
    final double tau = mc.abstentionRules.tau;
    final double delta = mc.abstentionRules.delta;

    final bool isUnderConf = maxProb < tau;
    final bool isLowMargin = margin < delta;

    if (isUnderConf || isLowMargin) {
      final String reason = isUnderConf && isLowMargin
          ? 'Prediction is uncertain: confidence (${(maxProb * 100).toStringAsFixed(1)}% < ${(tau * 100).toStringAsFixed(1)}%) and margin between top classes (${(margin * 100).toStringAsFixed(1)}% < ${(delta * 100).toStringAsFixed(1)}%) are below acceptance thresholds.'
          : isUnderConf
              ? 'Prediction confidence (${(maxProb * 100).toStringAsFixed(1)}% < ${(tau * 100).toStringAsFixed(1)}%) is below the acceptance threshold.'
              : 'Prediction is ambiguous: difference between top candidates (${(margin * 100).toStringAsFixed(1)}% < ${(delta * 100).toStringAsFixed(1)}%) is too small.';

      return ClassificationResult(
        status: ClassificationStatus.abstained,
        topPrediction: top1,
        allPredictions: predictions,
        qualityGateResult: qResult,
        statusReason: '$reason Please retake the photo on a plain white sheet with even lighting, or consult a citrus pathologist.',
        maxProbability: maxProb,
        margin: margin,
      );
    }

    // Accepted prediction
    return ClassificationResult(
      status: ClassificationStatus.accepted,
      topPrediction: top1,
      allPredictions: predictions,
      qualityGateResult: qResult,
      statusReason: 'Classification accepted with high confidence.',
      maxProbability: maxProb,
      margin: margin,
    );
  }

  @override
  Future<List<double>> runLogits(Float32List nchwTensor) async {
    if (_session == null) {
      throw StateError('InferenceService is not initialized.');
    }

    final runOptions = OrtRunOptions();
    try {
      // Shape: [1, 3, 320, 320]
      final inputOrt = OrtValueTensor.createTensorWithDataList(
        nchwTensor,
        [1, 3, kModelInputSize, kModelInputSize],
      );

      final inputs = {'input': inputOrt};
      final outputs = _session!.run(runOptions, inputs);

      inputOrt.release();

      // Output shape: [1, 5]
      final outputValue = outputs[0];
      final outputTensor = outputValue?.value as List<dynamic>;
      final row0 = outputTensor[0] as List<dynamic>;

      final List<double> result = row0.map((e) => (e as num).toDouble()).toList();

      for (final out in outputs) {
        out?.release();
      }

      return result;
    } finally {
      runOptions.release();
    }
  }


  @override
  void dispose() {
    _session?.release();
    _session = null;
    _isInitialized = false;
  }
}

