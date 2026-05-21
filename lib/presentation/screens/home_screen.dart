import 'package:flutter/material.dart';

import '../widgets/gradient_background.dart';
import 'online/online_menu_screen.dart';
import 'setup_screen.dart';

/// The first screen the player sees.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Icon(Icons.theater_comedy,
                    size: 96, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('IMPOSTER',
                    style: textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 4)),
                const SizedBox(height: 8),
                Text('A party word game',
                    style: textTheme.titleMedium
                        ?.copyWith(color: Colors.white70)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: textTheme.titleLarge,
                    ),
                    icon: const Icon(Icons.group),
                    label: const Text('Play Local'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SetupScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: textTheme.titleLarge,
                    ),
                    icon: const Icon(Icons.wifi),
                    label: const Text('Play Online'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const OnlineMenuScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.help_outline),
                  label: const Text('How to Play'),
                  onPressed: () => _showHowToPlay(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('How to Play'),
        content: const SingleChildScrollView(
          child: Text(
            '• Most players are CIVILIANS and see the secret word.\n'
            '• One or more players are IMPOSTERS and only see the theme.\n\n'
            '• Each player says a short clue about the word — without saying '
            'the word itself.\n'
            '• Imposters try to blend in and guess what the word might be.\n\n'
            '• After clues, everyone discusses and votes someone out.\n'
            '• Civilians win when all imposters are out.\n'
            '• Imposters win when they equal the number of civilians.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
