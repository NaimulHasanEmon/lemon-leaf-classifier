// lib/ui/screens/result_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/entities/classification_result.dart';
import '../../domain/entities/history_entry.dart';
import '../../inference/inference_service.dart';
import '../widgets/caution_banner.dart';
import '../widgets/confidence_bar.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List rawImageBytes;
  final String? imagePath;
  final InferenceService? inferenceService;

  const ResultScreen({
    super.key,
    required this.rawImageBytes,
    this.imagePath,
    this.inferenceService,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final InferenceService _inferenceService;
  final HistoryRepositoryImpl _historyRepo = HistoryRepositoryImpl();

  bool _isProcessing = true;
  String? _errorMessage;
  ClassificationResult? _result;

  @override
  void initState() {
    super.initState();
    _inferenceService = widget.inferenceService ?? OnnxRuntimeInferenceService();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      final result = await _inferenceService.classifyImage(widget.rawImageBytes);

      // Save to local SQLite database
      await _saveToHistory(result);

      if (mounted) {
        setState(() {
          _result = result;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _saveToHistory(ClassificationResult res) async {
    try {
      final entry = HistoryEntry(
        timestamp: DateTime.now(),
        imagePath: widget.imagePath,
        thumbnailBytes: widget.rawImageBytes.length > 50000 ? null : widget.rawImageBytes,
        status: res.status.name,
        predictedClass: res.topPrediction?.classLabel,
        probability: res.topPrediction?.probability,
        failureReason: res.statusReason,
      );
      await _historyRepo.insertEntry(entry);
    } catch (_) {
      // Non-fatal if persistence fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Evaluating quality & running model...'),
                  const SizedBox(height: 8),
                  Text(
                    'Stepwise halving → 384 quality check → 320 ONNX FP32',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _buildResultView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade700),
            const SizedBox(height: 16),
            const Text(
              'Analysis Failed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final res = _result!;
    final bool isHlb = res.topPrediction?.classLabel == kHlbClassLabel;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Captured Image Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.memory(
                widget.rawImageBytes,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status Specific Content
          if (res.isQualityRejected)
            _buildQualityRejectedCard(res)
          else if (res.isAbstained)
            _buildAbstainedCard(res)
          else
            _buildAcceptedCard(res),

          const SizedBox(height: 16),

          // Mandatory Caution Text & Disclaimers
          CautionBanner(isHlb: isHlb),

          const SizedBox(height: 20),

          // Retake Action Button
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retake Another Photo'),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityRejectedCard(ClassificationResult res) {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red.shade800),
                const SizedBox(width: 8),
                Text(
                  'Quality Gate Rejected',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'This photo does not satisfy the input quality criteria for the neural network. To avoid unreliable false predictions, inference was not executed.',
              style: TextStyle(fontSize: 13, height: 1.35),
            ),
            const Divider(height: 20),
            const Text(
              'Specific Failure Reasons:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ...res.qualityGateResult.failureReasons.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(r, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildMetricValueTable(res.qualityGateResult),
          ],
        ),
      ),
    );
  }

  Widget _buildAbstainedCard(ClassificationResult res) {
    return Card(
      elevation: 2,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade400),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Text(
                  'Prediction Uncertain (Abstained)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              res.statusReason,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
            const Divider(height: 20),
            const Text(
              'Preliminary Candidate Likelihoods (Uncertain):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...(() {
              final sorted = List.of(res.allPredictions)
                ..sort((a, b) => b.probability.compareTo(a.probability));
              return sorted.map((p) => ConfidenceBar(
                    label: p.displayName,
                    probability: p.probability,
                    isTop1: p == sorted.first,
                  ));
            })(),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedCard(ClassificationResult res) {
    final top1 = res.topPrediction!;
    final bool isHealthy = top1.classLabel == 'healthy_lemon_leaf';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconForClass(top1.classLabel),
                  color: isHealthy ? Colors.green.shade700 : Colors.red.shade700,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        top1.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Confidence: ${(top1.probability * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'All Class Probabilities (Raw Softmax):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            // Sort all 5 predictions by probability, highest first.
            ...(() {
              final sorted = List.of(res.allPredictions)
                ..sort((a, b) => b.probability.compareTo(a.probability));
              return sorted.map((p) => ConfidenceBar(
                    label: p.displayName,
                    probability: p.probability,
                    isTop1: p.classLabel == top1.classLabel,
                    isHealthy: p.classLabel == 'healthy_lemon_leaf',
                  ));
            })(),
            const SizedBox(height: 12),
            _buildMetricValueTable(res.qualityGateResult),
          ],
        ),
      ),
    );
  }

  /// Returns the correct icon for each disease class:
  /// HLB → virus/pathogen; leafminer/swallowtail → pest; leaf curl → distortion; healthy → leaf.
  static IconData _iconForClass(String label) {
    switch (label) {
      case kHlbClassLabel:          return Icons.coronavirus_outlined;
      case 'citrus_leafminer':      return Icons.pest_control_outlined;
      case 'swallowtail_herbivory': return Icons.pest_control_rodent_outlined;
      case 'citrus_leaf_curl':      return Icons.change_history_outlined;
      case 'healthy_lemon_leaf':    return Icons.eco_rounded;
      default:                      return Icons.eco_outlined;
    }
  }

  Widget _buildMetricValueTable(dynamic q) {
    final s = q.sharpness;
    final e = q.exposure;
    final b = q.borderBrightness;
    final sat = q.saturation;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quality Metrics (Canonical 384x384):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Sharpness: ${s.value.toStringAsFixed(1)} ${s.passed ? "✓" : "✗ (min 209.7)"}', style: const TextStyle(fontSize: 11)),
          Text('Exposure: ${e.value.toStringAsFixed(3)} ${e.passed ? "✓" : "✗ [0.625–0.871]"}', style: const TextStyle(fontSize: 11)),
          Text('Border Brightness: ${b.value.toStringAsFixed(3)} ${b.passed ? "✓" : "✗ (min 0.945)"}', style: const TextStyle(fontSize: 11)),
          Text('Saturation: ${sat.value.toStringAsFixed(3)} ${sat.passed ? "✓" : "✗ [0.117–0.340]"}', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

