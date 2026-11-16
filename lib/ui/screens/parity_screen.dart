// lib/ui/screens/parity_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../inference/image_preprocessor.dart';
import '../../inference/inference_service.dart';

class ParityScreen extends StatefulWidget {
  const ParityScreen({super.key});

  @override
  State<ParityScreen> createState() => _ParityScreenState();
}

class _ParityScreenState extends State<ParityScreen> {
  final OnnxRuntimeInferenceService _inferenceService = OnnxRuntimeInferenceService();

  bool _isRunning = false;
  int _currentIndex = 0;
  int _totalImages = 100;
  double _maxAbsDiff = 0.0;
  double _meanAbsDiffSum = 0.0;
  int _top1Matches = 0;
  bool _isComplete = false;
  String? _statusMessage;

  Future<void> _startParityTest() async {
    setState(() {
      _isRunning = true;
      _currentIndex = 0;
      _maxAbsDiff = 0.0;
      _meanAbsDiffSum = 0.0;
      _top1Matches = 0;
      _isComplete = false;
      _statusMessage = 'Initializing model...';
    });

    try {
      await _inferenceService.initialize();

      final String goldenStr = await rootBundle.loadString(kParityGoldenAssetPath);
      final Map<String, dynamic> goldenData = json.decode(goldenStr);
      final List<dynamic> entries = goldenData['images'] as List<dynamic>;

      _totalImages = entries.length;

      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i] as Map<String, dynamic>;
        final String filename = entry['filename'] as String;
        final List<dynamic> goldenLogitsDyn = entry['reference_logits'] ?? entry['logits'];
        final List<double> goldenLogits = goldenLogitsDyn.map((e) => (e as num).toDouble()).toList();

        final ByteData imgData = await rootBundle.load('assets/parity/$filename');
        final Uint8List imgBytes = imgData.buffer.asUint8List(imgData.offsetInBytes, imgData.lengthInBytes);

        // Preprocess to NCHW
        final preprocessed = ImagePreprocessor.processImage(imgBytes, _inferenceService.thresholds!);
        final List<double> onnxLogits = await _inferenceService.runLogits(preprocessed.nchwTensor);

        // Compute abs logit difference
        double currentMaxDiff = 0.0;
        double currentDiffSum = 0.0;

        for (int c = 0; c < 5; c++) {
          final diff = (onnxLogits[c] - goldenLogits[c]).abs();
          if (diff > currentMaxDiff) currentMaxDiff = diff;
          currentDiffSum += diff;
        }

        if (currentMaxDiff > _maxAbsDiff) {
          _maxAbsDiff = currentMaxDiff;
        }
        _meanAbsDiffSum += (currentDiffSum / 5.0);

        // Check top-1 match
        final int goldenTop1 = _argmax(goldenLogits);
        final int onnxTop1 = _argmax(onnxLogits);
        if (goldenTop1 == onnxTop1) {
          _top1Matches++;
        }

        if (mounted && (i % 5 == 0 || i == entries.length - 1)) {
          setState(() {
            _currentIndex = i + 1;
            _statusMessage = 'Tested $_currentIndex / $_totalImages images...';
          });
        }
      }

      setState(() {
        _isRunning = false;
        _isComplete = true;
        _statusMessage = 'Parity verification complete!';
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
        _statusMessage = 'Error during test: $e';
      });
    }
  }

  int _argmax(List<double> list) {
    int maxIdx = 0;
    double maxVal = list[0];
    for (int i = 1; i < list.length; i++) {
      if (list[i] > maxVal) {
        maxVal = list[i];
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  @override
  void dispose() {
    _inferenceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double top1Agreement = _totalImages > 0 ? (_top1Matches / _totalImages) * 100 : 0.0;
    final double meanAbsDiff = _currentIndex > 0 ? _meanAbsDiffSum / _currentIndex : 0.0;
    final bool passed = _isComplete && _maxAbsDiff <= 1.177 && top1Agreement >= 98.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('100-Image Parity Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stage 2/4 Verification Spec',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Runs all 100 locked parity test PNGs (20 per class) from assets through the on-device preprocessing and ONNX runtime pipeline, comparing predictions with stored PyTorch reference logits.',
                      style: TextStyle(fontSize: 12, height: 1.35),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Hard ceiling tolerance: max abs diff <= 1.177\n'
                      '• Top-1 agreement target: >= 98.0%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isRunning) ...[
              LinearProgressIndicator(value: _currentIndex / _totalImages),
              const SizedBox(height: 12),
              Center(child: Text(_statusMessage ?? '')),
            ] else if (_isComplete) ...[
              Card(
                elevation: 2,
                color: passed ? Colors.green.shade50 : Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: passed ? Colors.green.shade600 : Colors.red.shade600, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(passed ? Icons.check_circle : Icons.error, color: passed ? Colors.green.shade800 : Colors.red.shade800, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            passed ? 'PARITY VERIFIED (PASS)' : 'PARITY FAILED',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: passed ? Colors.green.shade900 : Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildStatRow('Images Tested', '$_currentIndex / $_totalImages'),
                      _buildStatRow('Top-1 Agreement', '${top1Agreement.toStringAsFixed(1)}% ($_top1Matches/$_totalImages)'),
                      _buildStatRow('Max Abs Logit Diff', _maxAbsDiff.toStringAsFixed(6)),
                      _buildStatRow('Mean Abs Logit Diff', meanAbsDiff.toStringAsFixed(6)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: Text(
                  _statusMessage ?? 'Press button below to run on-device parity test.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],

            const Spacer(),

            FilledButton.icon(
              onPressed: _isRunning ? null : _startParityTest,
              icon: const Icon(Icons.play_arrow),
              label: Text(_isRunning ? 'Testing...' : 'Run Parity Benchmark'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

