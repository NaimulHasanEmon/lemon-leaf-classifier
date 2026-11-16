// lib/ui/screens/home_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/first_launch_dialog.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirstLaunchDialog.showIfNeeded(context);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 3000,
        maxHeight: 3000,
        imageQuality: 95,
      );

      if (file == null) {
        setState(() => _isLoading = false);
        return;
      }

      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() => _isLoading = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ResultScreen(
            rawImageBytes: bytes,
            imagePath: file.path,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing image: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lemon Leaf Classifier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Capture Guide',
            onPressed: () => context.push('/guide'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Scan History',
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => context.push('/about'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analysing image…'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── App identity header ───────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.eco_rounded,
                            size: 32, color: colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lemon Leaf Classifier',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Research prototype · On-device AI',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Main action card ──────────────────────────────────
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 52, color: colorScheme.primary),
                          const SizedBox(height: 12),
                          const Text(
                            'Analyse a Lemon Leaf',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Place one leaf on a plain white sheet in even light.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera),
                            label: const Text('Take Photo'),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Select from Gallery'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Photography requirements card ─────────────────────
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.tips_and_updates_outlined,
                                      size: 18, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Photography Tips',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => context.push('/guide'),
                                child: const Text('Full Guide'),
                              ),
                            ],
                          ),
                          const Divider(height: 10),
                          _buildTip(
                              Icons.check_circle_outline,
                              'Plain white sheet behind the leaf'),
                          _buildTip(
                              Icons.check_circle_outline,
                              'Bright, even light — no shadows or glare'),
                          _buildTip(
                              Icons.check_circle_outline,
                              'Leaf fills roughly 30–40 % of the frame'),
                          _buildTip(
                              Icons.check_circle_outline,
                              'Camera steady, leaf in sharp focus'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Research prototype note ───────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBE6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.amber.shade400.withValues(alpha: 0.8)),
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
                            'diagnosis. Use on plain white-sheet photos only.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5A4000),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Hidden parity link ────────────────────────────────
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.push('/parity'),
                      icon: const Icon(Icons.bug_report_outlined, size: 15),
                      label: const Text('Parity Verification',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(text, style: const TextStyle(fontSize: 13, height: 1.3))),
        ],
      ),
    );
  }
}
