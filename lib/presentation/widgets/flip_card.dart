import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A hold-to-peek card that flips in 3D from [back] (the cover) to [front]
/// (the secret) while the user keeps a finger pressed on it. Releasing the
/// press flips it back to the cover.
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.frontColor,
    this.onFirstPeek,
    this.width = 300,
    this.height = 380,
  });

  /// Content shown while the card is held open.
  final Widget front;

  /// Content shown when the card is at rest (the cover).
  final Widget back;

  /// Optional fill for the revealed side (e.g. a faint role tint).
  final Color? frontColor;

  /// Fires once, the first time the user holds the card past the halfway
  /// flip point. Useful for "they have seen their card" tracking.
  final VoidCallback? onFirstPeek;

  final double width;
  final double height;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
    reverseDuration: const Duration(milliseconds: 250),
  )..addListener(_maybeFirePeek);

  bool _peeked = false;

  void _maybeFirePeek() {
    if (_peeked || _flip.value <= 0.5) return;
    _peeked = true;
    widget.onFirstPeek?.call();
  }

  @override
  void dispose() {
    _flip.removeListener(_maybeFirePeek);
    _flip.dispose();
    super.dispose();
  }

  void _press() => _flip.forward();
  void _release() => _flip.reverse();

  Widget _shell({required Widget child, Color? color}) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: color ?? AppColors.cardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Center(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listener (not GestureDetector) so press-down and release fire instantly
    // regardless of how long the user holds, with no long-press delay.
    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
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
