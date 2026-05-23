import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/game_providers.dart';
import '../widgets/gradient_background.dart';
import '../widgets/ui_kit.dart';
import 'online/online_menu_screen.dart';
import 'setup_screen.dart';

/// Icon used for each theme tile, keyed by the theme's id.
IconData themeIcon(String id) {
  switch (id) {
    case 'animals':
      return Icons.pets;
    case 'food':
      return Icons.restaurant;
    case 'movies':
      return Icons.movie_creation_outlined;
    case 'sports':
      return Icons.sports_soccer;
    case 'countries':
      return Icons.public;
    case 'jobs':
      return Icons.work_outline;
    case 'household':
      return Icons.chair_outlined;
    case 'famous_people':
      return Icons.star_outline;
    case 'video_games':
      return Icons.sports_esports;
    case 'nature':
      return Icons.park_outlined;
    default:
      return Icons.category_outlined;
  }
}

/// The first screen the player sees — the "Lobby".
class HomeScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final themesAsync = ref.watch(themesProvider);
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
              MenuCard(
                icon: Icons.wifi,
                title: 'Play Online',
                subtitle: 'Play with friends on other devices',
                showArrow: true,
                onTap: () => _openOnline(context),
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
              const SectionLabel('All Themes'),
              const SizedBox(height: 12),
              themesAsync.when(
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (themes) => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    for (final t in themes)
                      ThemeChipCard(
                        icon: themeIcon(t.id),
                        label: t.name,
                        onTap: () => _openSetup(context, themeName: t.name),
                      ),
                  ],
                ),
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
