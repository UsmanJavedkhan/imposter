import 'package:flutter/material.dart';

/// A small amber "Hint: …" pill shown on the imposter's role card so they
/// have a place to start without learning the secret word.
class HintChip extends StatelessWidget {
  const HintChip({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Hint: $text',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
