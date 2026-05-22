import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A tap-to-reveal card that flips in 3D from [back] (the cover) to [front]
/// (the secret). Calls [onRevealed] once, the first time it is flipped open.
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.frontColor,
    this.onRevealed,
    this.width = 300,
    this.height = 380,
  });

  /// Content shown once the card is flipped open.
  final Widget front;

  /// Content shown initially (the cover).
  final Widget back;

  /// Optional fill for the revealed side (e.g. a faint role tint).
  final Color? frontColor;

  /// Fired once when the card first finishes flipping open.
  final VoidCallback? onRevealed;

  final double width;
  final double height;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onRevealed?.call();
    });

  bool get _opened => _flip.value > 0.5;

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _reveal() {
    if (!_flip.isAnimating && _flip.value == 0) _flip.forward();
  }

  Widget _shell({required Widget child, Color? color}) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Center(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _opened ? null : _reveal,
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          final showFront = _flip.value > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_flip.value * math.pi),
            child: showFront
                // Mirror the front so its content reads correctly after 90°.
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _shell(color: widget.frontColor, child: widget.front),
                  )
                : _shell(child: widget.back),
          );
        },
      ),
    );
  }
}
