import 'package:flutter/material.dart';

/// Central palette + theme for the app.
///
/// Warm sunrise palette over a deep navy backdrop:
///   • primary  #F97316 (orange) — brand CTA accent
///   • amber    #FBBF24         — hint / highlight / section label
///   • cyan     #22D3EE         — info / selection accent
///   • neutral  #FFFBEB (cream) — primary CTA fill (dark text on top)
///
/// Imposter / civilian retain rose / mint so the role colors still read as
/// "bad" and "good" at a glance.
class AppColors {
  AppColors._();

  // Brand accents
  static const Color primary = Color(0xFFF97316); // orange (palette primary)
  static const Color cyan = Color(0xFF22D3EE); // cyan (palette tertiary)
  static const Color imposter = Color(0xFFFF5C7A); // rose (semantic)
  static const Color civilian = Color(0xFF34E0A1); // mint (semantic)
  static const Color amberHint = Color(0xFFFBBF24); // amber (palette secondary)

  // Brand wordmark gradient (orange → amber) and section label.
  static const Color magentaA = Color(0xFFF97316); // brand orange
  static const Color magentaB = Color(0xFFFBBF24); // brand amber
  static const List<Color> brandGradient = [magentaA, magentaB];
  static const Color labelPink = Color(0xFFFBBF24); // section label = amber

  // Orange primary-CTA fill (matches the mockup's "Start Game" / "Play Local"
  // / "Pass to Next" buttons), with crisp white text on top.
  // Constant names kept as `lavender` / `onLavender` so existing call sites
  // continue to work — the colours have just been re-skinned to the new
  // palette's primary.
  static const Color lavender = Color(0xFFF97316); // palette primary (orange)
  static const Color onLavender = Color(0xFFFFFFFF); // white text on orange

  // Card surfaces — slightly warmer alpha so the dark background reads
  // charcoal-with-warmth instead of cool grey.
  static Color cardFill = Colors.white.withValues(alpha: 0.04);
  static Color cardBorder = Colors.white.withValues(alpha: 0.08);

  // Background gradient stops — near-black with a warm undertone so orange
  // accents glow against it.
  static const Color bgTop = Color(0xFF0A0805);
  static const Color bgMid = Color(0xFF15100A);
  static const Color bgBottom = Color(0xFF1E1610);

  /// Default full-screen background gradient colours.
  static const List<Color> background = [bgTop, bgMid, bgBottom];

  /// Tint used behind the imposter reveal (warm rose, harmonised with orange).
  static const List<Color> imposterBackground = [
    Color(0xFF2A0A12),
    Color(0xFF5C1620),
    Color(0xFF7A1C2E),
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
    tertiary: AppColors.amberHint,
    surface: const Color(0xFF15100A),
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
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.bgMid,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.bgMid,
      modalBarrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bgMid,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
