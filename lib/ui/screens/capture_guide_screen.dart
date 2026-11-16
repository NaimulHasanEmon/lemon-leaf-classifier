// lib/ui/screens/capture_guide_screen.dart
import 'package:flutter/material.dart';

class CaptureGuideScreen extends StatelessWidget {
  const CaptureGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.blue.shade800),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Follow these 4 rules to pass the automated quality gate and receive reliable predictions.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildStepCard(
            context,
            stepNumber: '1',
            title: 'Use a Clean White Sheet',
            description:
                'Place a single leaf flat on a clean, blank white paper or poster board. The model was trained with white borders; natural foliage or soil backgrounds will trigger automatic rejection.',
            icon: Icons.note_outlined,
            isCritical: true,
          ),

          _buildStepCard(
            context,
            stepNumber: '2',
            title: 'Leaf Fills 30%–40% of the Frame',
            description:
                'Do not zoom in too close or stay too far. Position the leaf centrally so that the white background is clearly visible along all four borders (outer 5% of the frame).',
            icon: Icons.crop_square_rounded,
          ),

          _buildStepCard(
            context,
            stepNumber: '3',
            title: 'Ensure Bright, Even Lighting',
            description:
                'Take the photo under indirect daylight or diffused indoor lamps. Avoid harsh direct sunlight that casts dark leaf shadows or causes bright shiny reflections.',
            icon: Icons.wb_sunny_outlined,
          ),

          _buildStepCard(
            context,
            stepNumber: '4',
            title: 'Hold Camera Steady (Sharp Focus)',
            description:
                'Tap the screen on the leaf blade to focus. Blurry images will be rejected by the automated Laplacian sharpness gate (minimum sharpness threshold 209.7).',
            icon: Icons.center_focus_strong_rounded,
          ),

          const SizedBox(height: 16),
          const Text(
            'What Happens if Quality Fails?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'The app evaluates sharpness, brightness exposure, border background purity, and colour saturation before running the neural network. If any test fails, you will be prompted to retake the photo with specific feedback.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    bool isCritical = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isCritical
            ? BorderSide(color: Colors.amber.shade700, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isCritical
                  ? Colors.amber.shade100
                  : Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                stepNumber,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCritical
                      ? Colors.amber.shade900
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

