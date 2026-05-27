import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import 'pressable_scale.dart';

/// The "primary CTA" button style used across the app — solid coral red fill
/// with crisp white text. Generous horizontal padding so content-sized
/// buttons (Start Clues, Pass to Next, …) read as proper pill CTAs.
/// Full-width buttons (wrapped in SizedBox(width: infinity)) ignore the
/// extra horizontal padding, so this is safe everywhere.
ButtonStyle lavenderButtonStyle() => FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
      minimumSize: const Size(160, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );

/// The "IMPOSTER" wordmark rendered in solid coral red. The previous gradient
/// variant lives on for backwards-compat but the single-tone red matches the
/// supplied mockups better.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.fontSize = 44,
    this.letterSpacing = 3,
    this.color = AppColors.primary,
  });

  final double fontSize;
  final double letterSpacing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'IMPOSTER',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: letterSpacing,
        color: color,
        height: 1.0,
      ),
    );
  }
}

/// Small uppercase, letter-spaced section heading (e.g. PLAYERS / THEME).
/// Defaults to the secondary-accent blue so it reads as quiet metadata.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = AppColors.labelPink});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}

/// Legacy decorative "mask face" — kept so any older screen still using it
/// keeps compiling, but the new home screen uses the imposter character
/// image instead.
class MaskFace extends StatelessWidget {
  const MaskFace({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size * 0.12,
      height: size * 0.12,
      decoration: const BoxDecoration(
        color: AppColors.textSecondary,
        shape: BoxShape.circle,
      ),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [dot, SizedBox(width: size * 0.14), dot],
      ),
    );
  }
}

/// A rounded tappable row card with an icon tile, title and subtitle.
///
/// Two variants:
///   • [filled] with [accent]=red → big coral "Play Local" card (white text)
///   • [filled] with [accent]=blue → big indigo "Play Online" card (white text)
///   • not filled → outlined white card with dark text and an accent icon tile
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent = AppColors.cyan,
    this.filled = false,
    this.showArrow = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final bool filled;
  final bool showArrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = filled ? Colors.white : AppColors.textPrimary;
    final subColor =
        filled ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary;
    final iconBg = filled
        ? Colors.white
        : accent.withValues(alpha: 0.12);
    final iconColor = filled ? accent : accent;

    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: filled ? accent : AppColors.cardFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: filled ? Colors.transparent : AppColors.cardBorder,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: titleColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: TextStyle(color: subColor, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                if (showArrow)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: filled
                          ? Colors.white
                          : AppColors.bgMid,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward,
                        size: 18,
                        color: filled ? accent : AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small theme tile (icon + label) used in the ALL THEMES grid. Each tile
/// gets a pastel background and a brighter accent for the icon — colours
/// keyed off the theme id via `AppColors.themeTileColors`.
class ThemeChipCard extends StatelessWidget {
  const ThemeChipCard({
    super.key,
    required this.icon,
    required this.label,
    required this.themeId,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String themeId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (tileBg, tileFg) = AppColors.themeTileColors(themeId);
    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.cardFill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: tileBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tileFg, size: 28),
                ),
                const SizedBox(height: 10),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The three bottom-nav tabs used across the app.
enum AppTab { lobby, play, rules }

/// Bottom navigation bar matching the design — white surface with a soft
/// rounded pill behind the active tab (coral-tinted with red icon + label).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, required this.onTap});

  final AppTab current;
  final ValueChanged<AppTab> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: EdgeInsets.only(
        top: 10,
        bottom: 10 + MediaQuery.of(context).padding.bottom,
        left: 12,
        right: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _item(AppTab.lobby, Icons.groups, 'Lobby'),
          _item(AppTab.play, Icons.sports_esports, 'Play'),
          _item(AppTab.rules, Icons.menu_book, 'Rules'),
        ],
      ),
    );
  }

  Widget _item(AppTab tab, IconData icon, String label) {
    final active = tab == current;
    final fg = active ? AppColors.primary : AppColors.textSecondary;
    final bg = active
        ? AppColors.primary.withValues(alpha: 0.12)
        : Colors.transparent;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 22),
              if (active) ...[
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ] else ...[
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The hero character. The source artwork (`imposter_hero.svg`) ships with
/// its own speech bubble, so this widget just renders the SVG — no overlays,
/// no extra Stack chrome. SVG is rendered via `flutter_svg` so it scales
/// crisply at any size without bitmap blurring.
class ImposterHero extends StatelessWidget {
  const ImposterHero({super.key, this.size = 180});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/imposter_hero.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => SizedBox(width: size, height: size),
    );
  }
}
