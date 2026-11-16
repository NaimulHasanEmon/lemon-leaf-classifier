// lib/ui/screens/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Privacy guarantee ─────────────────────────────────────────
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security,
                          color: colorScheme.onPrimaryContainer),
                      const SizedBox(width: 10),
                      Text(
                        '100 % Offline & Private',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• No internet permission — the app cannot connect to any network.\n'
                    '• All inference runs locally on your device CPU.\n'
                    '• Photos and scan history are stored only on this device.',
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Model info ────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.memory_outlined,
                          size: 20, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Deployed Model',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 16),
                  _infoRow('Architecture', 'ConvNeXt-Tiny (timm)'),
                  _infoRow('Precision', 'FP32 ONNX'),
                  _infoRow('Input size', '320 × 320 px'),
                  _infoRow('Classes', '5 lemon-leaf conditions'),
                  _infoRow('Runtime', 'ONNX Runtime Android'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Disclaimer ────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBE6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.amber.shade400.withValues(alpha: 0.7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Research prototype. Not a substitute for expert '
                    'diagnosis. Confirm all findings with your local '
                    'agriculture extension officer.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5A4000),
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 13, color: Colors.black54))),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
