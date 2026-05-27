import 'package:flutter/material.dart';

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
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tileBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tileFg, size: 24),
                ),
                const SizedBox(height: 8),
                // FittedBox keeps the label fully readable on the narrowest
                // phones (a 4-column grid leaves ~70 px per tile, which is
                // tight for words like "Animals" / "Countries").
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
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

/// The hero character. Just the PNG — no chrome. The home screen wraps this
/// in a `HeroBlock` which adds the decorative sparkles, speech bubble and
/// settings cog around it.
class ImposterHero extends StatelessWidget {
  const ImposterHero({super.key, this.size = 180});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/imposter_hero.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.theater_comedy,
            color: Colors.white, size: 64),
      ),
    );
  }
}

/// Home-screen hero block: scattered sparkle / ghost decorations behind the
/// character, a speech-bubble badge on the left, and a settings cog in the
/// top-right corner. Composed in one widget so the home screen can drop it
/// in without piling Stack code into its build method.
class HeroBlock extends StatelessWidget {
  const HeroBlock({
    super.key,
    this.heroSize = 180,
    this.onSettingsTap,
  });

  /// Size of the character image inside the block.
  final double heroSize;

  /// Tapped when the user presses the settings cog. If null the cog is hidden.
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    // Reserve a fixed band of vertical space so the sparkles and settings cog
    // don't shift around as the parent ListView scrolls. Slightly taller than
    // the hero so the speech bubble has somewhere to sit above it.
    final blockHeight = heroSize + 48;
    // Tightly nest the character + speech bubble so the bubble always sits
    // adjacent to the character's upper-left, regardless of screen width.
    final inner = SizedBox(
      width: heroSize + 56,
      height: heroSize + 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: ImposterHero(size: heroSize),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: const _SpeechBubble(),
          ),
        ],
      ),
    );
    return SizedBox(
      height: blockHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative sparkles + tiny crewmate ghosts behind the character.
          Positioned.fill(
            child: IgnorePointer(child: _HeroDecorations()),
          ),
          // Settings cog in the top-right (opt-in).
          if (onSettingsTap != null)
            Positioned(
              top: 0,
              right: 0,
              child: _CircleIconButton(
                icon: Icons.settings_outlined,
                onPressed: onSettingsTap!,
              ),
            ),
          Align(alignment: Alignment.bottomCenter, child: inner),
        ],
      ),
    );
  }
}

/// Scatters small sparkle icons + tiny "ghost" silhouettes across the hero
/// block in a soft warm grey so they read as decoration, not content.
class _HeroDecorations extends StatelessWidget {
  // Each entry: dx/dy in [0..1] of the block, icon, size, opacity. Hand-picked
  // so the scatter looks intentional rather than uniform.
  static const List<(double, double, IconData, double, double)> _items = [
    (0.06, 0.10, Icons.star_rate_rounded, 14, 0.30),
    (0.16, 0.42, Icons.star_rate_rounded, 10, 0.22),
    (0.10, 0.78, Icons.star_rate_rounded, 12, 0.26),
    (0.90, 0.08, Icons.star_rate_rounded, 12, 0.26),
    (0.84, 0.36, Icons.star_rate_rounded, 16, 0.30),
    (0.96, 0.62, Icons.star_rate_rounded, 10, 0.22),
    (0.78, 0.88, Icons.star_rate_rounded, 12, 0.26),
  ];

  // Tiny crewmate silhouettes — same scatter approach but using a custom shape
  // (a rounded body with a visor bump) so they read as Among-Us-style ghosts.
  static const List<(double, double, double)> _ghosts = [
    (0.86, 0.18, 18),
    (0.04, 0.60, 16),
    (0.88, 0.78, 14),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Stack(
          children: [
            for (final (dx, dy, icon, size, opacity) in _items)
              Positioned(
                left: dx * c.maxWidth - size / 2,
                top: dy * c.maxHeight - size / 2,
                child: Icon(icon,
                    size: size,
                    color: AppColors.textTertiary.withValues(alpha: opacity)),
              ),
            for (final (dx, dy, size) in _ghosts)
              Positioned(
                left: dx * c.maxWidth - size / 2,
                top: dy * c.maxHeight - size / 2,
                child: CustomPaint(
                  size: Size(size, size * 1.15),
                  painter: _GhostPainter(
                    color: AppColors.textTertiary.withValues(alpha: 0.22),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Paints a tiny Among-Us-style crewmate silhouette: rounded body + visor.
class _GhostPainter extends CustomPainter {
  _GhostPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    // Body — a tall pill with a slightly narrower bottom.
    final body = Path()
      ..moveTo(w * 0.15, h * 0.45)
      // Top arc
      ..quadraticBezierTo(w * 0.5, -h * 0.05, w * 0.85, h * 0.45)
      // Right side down
      ..lineTo(w * 0.85, h * 0.90)
      // Bottom right foot
      ..quadraticBezierTo(w * 0.75, h, w * 0.62, h)
      ..lineTo(w * 0.50, h)
      // Bottom dip
      ..quadraticBezierTo(w * 0.48, h * 0.92, w * 0.42, h * 0.92)
      // Bottom left foot
      ..lineTo(w * 0.30, h * 0.92)
      ..quadraticBezierTo(w * 0.15, h * 0.92, w * 0.15, h * 0.80)
      ..close();
    canvas.drawPath(body, paint);
    // Visor — flat-ish oval in a slightly lighter tone.
    final visor = Paint()..color = color.withValues(alpha: color.a * 0.6);
    canvas.drawOval(
      Rect.fromLTWH(w * 0.30, h * 0.18, w * 0.55, h * 0.30),
      visor,
    );
  }

  @override
  bool shouldRepaint(covariant _GhostPainter old) => old.color != color;
}

/// White rounded "speech bubble" pill with three blue dots, used on the home
/// hero so the character looks like it's whispering — also matches the
/// mockup exactly.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.cyan,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Small white circular button used inside the hero block (settings cog).
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
