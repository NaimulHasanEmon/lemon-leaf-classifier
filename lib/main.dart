// lib/main.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/app_theme.dart';
import 'ui/screens/about_screen.dart';
import 'ui/screens/capture_guide_screen.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/parity_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() {
  runApp(const LemonLeafApp());
}

class LemonLeafApp extends StatelessWidget {
  const LemonLeafApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lemon Leaf Classifier',
      theme: buildAppTheme(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: '/guide',
          builder: (context, state) => const CaptureGuideScreen()),
      GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen()),
      GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen()),
      GoRoute(
          path: '/about',
          builder: (context, state) => const AboutScreen()),
      GoRoute(
          path: '/parity',
          builder: (context, state) => const ParityScreen()),
    ],
  );
}
