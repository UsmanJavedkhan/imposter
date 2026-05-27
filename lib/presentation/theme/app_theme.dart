import 'package:flutter/material.dart';

/// Central palette + theme for the app.
///
/// New "imposter playful" look — light surfaces, navy text, coral-red primary
/// CTA, blue secondary CTA, and soft pastel tile accents for the theme grid.
/// Imposter / civilian retain warm rose / cool mint so role colours still read
/// as "bad" and "good" at a glance.
///
/// Constant names (`primary`, `cyan`, `lavender`, `bgTop`, …) are kept from
/// the previous palette so every call site updates automatically — the colour
/// values have just been re-skinned.
class AppColors {
  AppColors._();

  // --- Brand accents -------------------------------------------------------

  /// Coral red used for the primary CTA and the IMPOSTER wordmark.
  static const Color primary = Color(0xFFEE5A5A);

  /// Indigo-blue used for secondary CTAs (Play Online / Add player / theme
  /// section label) — sits next to the coral primary without clashing.
  static const Color cyan = Color(0xFF5468E7);

  /// Rose used for the imposter role tint (semantic).
  static const Color imposter = Color(0xFFFF5C7A);

  /// Mint used for the civilian role tint (semantic).
  static const Color civilian = Color(0xFF34C089);

  /// Warm amber for hint chips.
  static const Color amberHint = Color(0xFFF7B432);

  // --- Brand wordmark ------------------------------------------------------

  /// Wordmark gradient stops (kept as `magentaA` / `magentaB` so existing
  /// references continue to compile — the colours are now coral → deeper red).
  static const Color magentaA = Color(0xFFEE5A5A);
  static const Color magentaB = Color(0xFFD63C5E);
  static const List<Color> brandGradient = [magentaA, magentaB];

  /// Small uppercase section labels (PLAYERS / THEME / IMPOSTERS) sit in the
  /// secondary blue so they read as quiet metadata against dark navy headings.
  static const Color labelPink = cyan;

  // --- Primary CTA (kept under the old `lavender` name) --------------------

  /// Primary CTA fill — coral red.
  static const Color lavender = primary;

  /// Text colour on top of the primary CTA.
  static const Color onLavender = Color(0xFFFFFFFF);

  // --- Card surfaces -------------------------------------------------------

  /// White cards with a very subtle warm-gray border.
  static Color cardFill = Colors.white;
  static const Color cardBorder = Color(0xFFE8EAF0);

  // --- Text colours --------------------------------------------------------

  /// Deep navy used for headings / primary text on the light background.
  static const Color textPrimary = Color(0xFF0D1A2D);

  /// Muted gray used for subtitles, helper text, captions.
  static const Color textSecondary = Color(0xFF6B7280);

  /// Light gray used for the lightest hint text / disabled state.
  static const Color textTertiary = Color(0xFF9CA3AF);

  // --- Background ---------------------------------------------------------

  /// The three-stop background gradient. All three sit very close so the
  /// app reads as a clean off-white wash rather than a visible gradient.
  static const Color bgTop = Color(0xFFFFFFFF);
  static const Color bgMid = Color(0xFFF8FAFC);
  static const Color bgBottom = Color(0xFFF1F3F8);
  static const List<Color> background = [bgTop, bgMid, bgBottom];

  /// Tint used behind the imposter reveal — stays warm + dark so the secret
  /// surface still feels distinct from the main app.
  static const List<Color> imposterBackground = [
    Color(0xFF1B0810),
    Color(0xFF3A0F20),
    Color(0xFF5C1830),
  ];

  /// Tint used behind a civilian / winning reveal.
  static const List<Color> civilianBackground = [
    Color(0xFF06231A),
    Color(0xFF0F4F3A),
    Color(0xFF15604A),
  ];

  // --- Soft pastel chips used in the theme grid ----------------------------

  /// Picks a pastel background + accent colour pair for a theme tile,
  /// keyed off the theme's id. Falls back to a neutral gray pair.
  static (Color bg, Color fg) themeTileColors(String id) {
    switch (id) {
      case 'animals':
        return (Color(0xFFFFE5EA), Color(0xFFEE5A5A));
      case 'food':
        return (Color(0xFFFFF4D6), Color(0xFFF59E0B));
      case 'movies':
        return (Color(0xFFEDE7FF), Color(0xFF7C5CFB));
      case 'sports':
      case 'video_games':
        return (Color(0xFFD8F5E5), Color(0xFF22C078));
      case 'countries':
        return (Color(0xFFD7E7FE), Color(0xFF2F6BE6));
      case 'jobs':
        return (Color(0xFFE9F0FF), Color(0xFF5468E7));
      case 'household':
        return (Color(0xFFF1E9DC), Color(0xFFA67B49));
      case 'famous_people':
        return (Color(0xFFFFE9CC), Color(0xFFF59E0B));
      case 'nature':
        return (Color(0xFFE0F1E2), Color(0xFF3CA45A));
      default:
        return (Color(0xFFF1F3F8), Color(0xFF6B7280));
    }
  }
}

/// Builds the app-wide Material 3 LIGHT theme.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.cyan,
    onSecondary: Colors.white,
    tertiary: AppColors.amberHint,
    surface: Colors.white,
    onSurface: AppColors.textPrimary,
  );

  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: _textTheme,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardFill,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.cardBorder),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.cyan),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: AppColors.textTertiary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

const TextTheme _textTheme = TextTheme(
  // Headlines render as deep navy by default; widgets override colour
  // explicitly where needed.
  displayLarge: TextStyle(color: AppColors.textPrimary),
  displayMedium: TextStyle(color: AppColors.textPrimary),
  displaySmall: TextStyle(color: AppColors.textPrimary),
  headlineLarge: TextStyle(color: AppColors.textPrimary),
  headlineMedium: TextStyle(color: AppColors.textPrimary),
  headlineSmall: TextStyle(color: AppColors.textPrimary),
  titleLarge: TextStyle(color: AppColors.textPrimary),
  titleMedium: TextStyle(color: AppColors.textPrimary),
  titleSmall: TextStyle(color: AppColors.textPrimary),
  bodyLarge: TextStyle(color: AppColors.textPrimary),
  bodyMedium: TextStyle(color: AppColors.textPrimary),
  bodySmall: TextStyle(color: AppColors.textSecondary),
  labelLarge: TextStyle(color: AppColors.textPrimary),
  labelMedium: TextStyle(color: AppColors.textSecondary),
  labelSmall: TextStyle(color: AppColors.textTertiary),
);
