import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Overlays a one-shot confetti burst on top of [child]. Fires automatically
/// when shown (used on the game-over screens when a side wins).
class WinConfetti extends StatefulWidget {
  const WinConfetti({super.key, required this.child, this.colors});

  final Widget child;
  final List<Color>? colors;

  @override
  State<WinConfetti> createState() => _WinConfettiState();
}

class _WinConfettiState extends State<WinConfetti> {
  late final ConfettiController _controller =
      ConfettiController(duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ??
        const [
          AppColors.primary,
          AppColors.cyan,
          AppColors.civilian,
          AppColors.amberHint,
          Colors.white,
        ];
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.05,
            numberOfParticles: 24,
            maxBlastForce: 22,
            minBlastForce: 8,
            gravity: 0.25,
            colors: colors,
            // Slight downward bias so the burst rains across the screen.
            blastDirection: math.pi / 2,
          ),
        ),
      ],
    );
  }
}
