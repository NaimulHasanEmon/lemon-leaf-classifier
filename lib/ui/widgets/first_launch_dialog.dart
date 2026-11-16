// lib/ui/widgets/first_launch_dialog.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

class FirstLaunchDialog extends StatelessWidget {
  const FirstLaunchDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool done = prefs.getBool(kPrefFirstLaunchDone) ?? false;
    if (!done && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const FirstLaunchDialog(),
      );
      await prefs.setBool(kPrefFirstLaunchDone, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.eco_rounded,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Welcome',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBE6),
                border: Border.all(
                    color: Colors.amber.shade400.withValues(alpha: 0.7)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Research prototype. Not a substitute for expert diagnosis.',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A4000),
                    height: 1.4),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'This app classifies lemon leaf conditions from photos taken '
              'on a plain white background. It is an offline tool for '
              'educational and research use only.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'How to get a good result:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              '• Place one detached leaf on a clean white sheet of paper.\n'
              '• Use bright, even, diffused light — avoid direct sunlight.\n'
              '• Keep the camera steady with the leaf in sharp focus.\n'
              '• The app will tell you if the photo quality is insufficient.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              'Always confirm any finding with your local agriculture extension officer.',
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Understood'),
        ),
      ],
    );
  }
}
