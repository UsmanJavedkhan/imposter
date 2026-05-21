import 'package:flutter/material.dart';

/// A full-screen gradient backdrop used to give screens a branded look.
///
/// Wrap a screen's body in this to get a consistent dark-purple gradient.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
  });

  final Widget child;

  /// Optional override colours (e.g. red tint for the imposter reveal).
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ??
              const [
                Color(0xFF1A1033),
                Color(0xFF2A1A5E),
                Color(0xFF3A1C71),
              ],
        ),
      ),
      child: child,
    );
  }
}
