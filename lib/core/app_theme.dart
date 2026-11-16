// lib/core/app_theme.dart
//
// Material 3 theme for the Lemon Leaf Classifier app.
// Uses a green-and-yellow palette appropriate for a plant-disease context.

import 'package:flutter/material.dart';

/// Returns the app's [ThemeData].
ThemeData buildAppTheme() {
  const seed = Color(0xFF4CAF50); // green seed
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ),
    // App bar
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),
    // Cards
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    // Filled buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    // Elevated buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    // Text
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(height: 1.5),
    ),
  );
}

// ─── Semantic colours used across the app ─────────────────────────────────────

/// Red banner colour for quality failures.
const Color kQualityFailColour = Color(0xFFD32F2F);

/// Amber/yellow banner colour for abstention.
const Color kAbstainColour = Color(0xFFF57F17);

/// Green for healthy class.
const Color kHealthyColour = Color(0xFF2E7D32);

/// Background colour for warning banners.
const Color kWarningBannerBg = Color(0xFFFFF8E1);
