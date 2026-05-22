import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A full-screen, slowly-shifting gradient backdrop used to give screens a
/// branded, living look. The gradient's begin/end alignment drifts back and
/// forth so the background feels alive without being distracting.
class GradientBackground extends StatefulWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
  });

  final Widget child;

  /// Optional override colours (e.g. rose tint for the imposter reveal).
  final List<Color>? colors;

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? AppColors.background;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final begin = Alignment.lerp(
            Alignment.topLeft, Alignment.topRight, t)!;
        final end = Alignment.lerp(
            Alignment.bottomRight, Alignment.bottomLeft, t)!;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: colors,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
