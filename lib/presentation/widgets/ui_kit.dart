import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pressable_scale.dart';

/// The "IMPOSTER" wordmark rendered with the pink→magenta brand gradient.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.fontSize = 44,
    this.letterSpacing = 3,
  });

  final double fontSize;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) =>
          const LinearGradient(colors: AppColors.brandGradient).createShader(rect),
      child: Text(
        'IMPOSTER',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: letterSpacing,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}

/// A small uppercase, letter-spaced section heading (e.g. "RECENT THEMES").
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
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
    );
  }
}

/// A decorative blank "mask" face: a soft circle with two dot eyes.
class MaskFace extends StatelessWidget {
  const MaskFace({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size * 0.12,
      height: size * 0.12,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [dot, SizedBox(width: size * 0.14), dot],
      ),
    );
  }
}

/// A rounded tappable card with an icon, title and subtitle.
///
/// [filled] gives the lavender primary look (dark text); otherwise it's a dark
/// translucent surface with an [accent]-coloured icon.
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
    final titleColor = filled ? AppColors.onLavender : Colors.white;
    final subColor = filled
        ? AppColors.onLavender.withValues(alpha: 0.65)
        : Colors.white60;
    final iconColor = filled ? AppColors.onLavender : accent;
    final iconBg = filled
        ? AppColors.onLavender.withValues(alpha: 0.10)
        : accent.withValues(alpha: 0.16);

    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: filled ? AppColors.lavender : AppColors.cardFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: filled ? Colors.transparent : AppColors.cardBorder),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: TextStyle(color: subColor, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                if (showArrow)
                  Icon(Icons.arrow_forward, color: titleColor.withValues(alpha: 0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small theme tile (icon + label) for the "Recent Themes" row. When
/// [highlighted] it uses a cyan gradient, otherwise a dark surface.
class ThemeChipCard extends StatelessWidget {
  const ThemeChipCard({
    super.key,
    required this.icon,
    required this.label,
    this.highlighted = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            height: 100,
            decoration: BoxDecoration(
              gradient: highlighted
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0E6E78), Color(0xFF1AA6B8)],
                    )
                  : null,
              color: highlighted ? null : AppColors.cardFill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: highlighted
                    ? AppColors.cyan.withValues(alpha: 0.6)
                    : AppColors.cardBorder,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon,
                    color: highlighted ? Colors.white : AppColors.cyan, size: 22),
                const Spacer(),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
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

/// Bottom navigation bar matching the design: Lobby / Play / Rules.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, required this.onTap});

  final AppTab current;
  final ValueChanged<AppTab> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
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
    final color = active ? AppColors.cyan : Colors.white54;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(tab),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
