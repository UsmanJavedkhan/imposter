import 'package:flutter/material.dart';

/// Central palette + theme for the app.
///
/// A fresh "midnight party" look: a deep indigo→violet background with a
/// violet primary, electric-cyan secondary, rose for the imposter and mint
/// for civilians / wins.
class AppColors {
  AppColors._();

  // Brand accents
  static const Color primary = Color(0xFF8B6CFF); // violet
  static const Color cyan = Color(0xFF22D3EE); // electric cyan
  static const Color imposter = Color(0xFFFF5C7A); // rose
  static const Color civilian = Color(0xFF34E0A1); // mint
  static const Color amberHint = Color(0xFFFFC857);

  // Background gradient stops (dark).
  static const Color bgTop = Color(0xFF120A2E);
  static const Color bgMid = Color(0xFF2A1A66);
  static const Color bgBottom = Color(0xFF4A1E8A);

  /// Default full-screen background gradient colours.
  static const List<Color> background = [bgTop, bgMid, bgBottom];

  /// Tint used behind the imposter reveal.
  static const List<Color> imposterBackground = [
    Color(0xFF2E0A1E),
    Color(0xFF5E163A),
    Color(0xFF7A1C45),
  ];

  /// Tint used behind a civilian / winning reveal.
  static const List<Color> civilianBackground = [
    Color(0xFF06231A),
    Color(0xFF0F4F3A),
    Color(0xFF15604A),
  ];
}

/// Builds the app-wide Material 3 dark theme.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    secondary: AppColors.cyan,
    tertiary: AppColors.imposter,
    surface: const Color(0xFF1A1340),
  );

  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
