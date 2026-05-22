import 'package:flutter/material.dart';

import '../widgets/gradient_background.dart';
import '../widgets/ui_kit.dart';
import 'online/online_menu_screen.dart';
import 'setup_screen.dart';

/// The first screen the player sees — the "Lobby".
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openSetup(BuildContext context, {String? themeName}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SetupScreen(initialThemeName: themeName),
      ),
    );
  }

  void _openOnline(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnlineMenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: BrandWordmark(fontSize: 18, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings coming soon')),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MaskFace(),
                  SizedBox(width: 14),
                  MaskFace(),
                ],
              ),
              const SizedBox(height: 28),
              const Center(child: BrandWordmark(fontSize: 46)),
              const SizedBox(height: 6),
              const Center(
                child: Text('A party word game',
                    style: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 28),
              MenuCard(
                icon: Icons.groups,
                title: 'Play Local',
                subtitle: 'Pass & Play with friends',
                filled: true,
                showArrow: true,
                onTap: () => _openSetup(context),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MenuCard(
                      icon: Icons.wifi,
                      title: 'Play Online',
                      subtitle: 'Global matchmaking',
                      onTap: () => _openOnline(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MenuCard(
                      icon: Icons.lock_outline,
                      title: 'Private',
                      subtitle: 'Invite via code',
                      accent: Colors.white70,
                      onTap: () => _openOnline(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MenuCard(
                icon: Icons.help_outline,
                title: 'How to Play',
                subtitle: 'Learn the rules of deception',
                accent: Colors.white70,
                onTap: () => showHowToPlay(context),
              ),
              const SizedBox(height: 24),
              const SectionLabel('Recent Themes'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ThemeChipCard(
                      icon: Icons.restaurant,
                      label: 'Foodies',
                      onTap: () =>
                          _openSetup(context, themeName: 'Food & Drink'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ThemeChipCard(
                      icon: Icons.movie_creation_outlined,
                      label: 'Hollywood',
                      highlighted: true,
                      onTap: () => _openSetup(context, themeName: 'Movies'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ThemeChipCard(
                      icon: Icons.rocket_launch_outlined,
                      label: 'Sci-Fi',
                      onTap: () => _openSetup(context, themeName: 'Video Games'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: AppTab.lobby,
        onTap: (tab) {
          switch (tab) {
            case AppTab.lobby:
              break;
            case AppTab.play:
              _openSetup(context);
            case AppTab.rules:
              showHowToPlay(context);
          }
        },
      ),
    );
  }
}

/// Shared "How to Play" dialog (used by the home card and the Rules tab).
void showHowToPlay(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('How to Play'),
      content: const SingleChildScrollView(
        child: Text(
          '• Most players are CIVILIANS and see the secret word.\n'
          '• One or more players are IMPOSTERS and only see the theme '
          'plus a related-word hint.\n\n'
          '• Each player gives a short clue about the word — without saying '
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
