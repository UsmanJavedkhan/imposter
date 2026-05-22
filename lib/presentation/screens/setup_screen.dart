import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/game_providers.dart';
import '../../domain/engine/imposter_rules.dart';
import '../../domain/models/game_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/ui_kit.dart';
import 'game_screen.dart';
import 'home_screen.dart' show showHowToPlay;

/// Lets the host add players, pick a theme, and choose the imposter count.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key, this.initialThemeName});

  /// Optional theme to pre-select (e.g. from the home "Recent Themes" row).
  final String? initialThemeName;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  // One text controller per player name field. Start with 4 players.
  final List<TextEditingController> _nameControllers = List.generate(
    4,
    (i) => TextEditingController(text: 'Player ${i + 1}'),
  );

  GameTheme? _selectedTheme;
  int _imposterCount = 1;

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    if (_nameControllers.length >= kMaxPlayers) return;
    setState(() {
      _nameControllers.add(
        TextEditingController(text: 'Player ${_nameControllers.length + 1}'),
      );
      _clampImposterCount();
    });
  }

  void _removePlayer(int index) {
    if (_nameControllers.length <= kMinPlayers) return;
    setState(() {
      _nameControllers.removeAt(index).dispose();
      _clampImposterCount();
    });
  }

  /// Keep the imposter count within the fair range for the player count.
  void _clampImposterCount() {
    final maxAllowed = maxImposters(_nameControllers.length);
    if (_imposterCount > maxAllowed) _imposterCount = maxAllowed;
    if (_imposterCount < 1) _imposterCount = 1;
  }

  void _start() {
    final names = _nameControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (names.length < kMinPlayers) {
      _snack('Add at least $kMinPlayers players with names.');
      return;
    }
    if (_selectedTheme == null) {
      _snack('Pick a theme first.');
      return;
    }

    ref.read(gameControllerProvider.notifier).startLocalGame(
          names: names,
          theme: _selectedTheme!,
          imposterCount: _imposterCount,
        );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickTheme(List<GameTheme> themes) async {
    final picked = await showModalBottomSheet<GameTheme>(
      context: context,
      backgroundColor: const Color(0xFF1A1340),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SectionLabel('Choose a theme'),
            ),
            for (final t in themes)
              ListTile(
                leading: Icon(
                  t.id == _selectedTheme?.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: AppColors.cyan,
                ),
                title: Text(t.name),
                subtitle: Text('${t.words.length} words'),
                onTap: () => Navigator.pop(ctx, t),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _selectedTheme = picked);
  }

  @override
  Widget build(BuildContext context) {
    final themesAsync = ref.watch(themesProvider);
    final maxAllowed = maxImposters(_nameControllers.length);

    return Scaffold(
      appBar: AppBar(
        title: const BrandWordmark(fontSize: 18, letterSpacing: 2),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: themesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Could not load themes:\n$e')),
            data: (themes) {
              _selectedTheme ??= _initialTheme(themes);
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text('Game Setup',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Prepare for the mystery',
                      style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 24),
                  SectionLabel('Players (${_nameControllers.length})',
                      color: AppColors.cyan),
                  const SizedBox(height: 12),
                  ..._buildPlayerFields(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.magentaA),
                      onPressed: _nameControllers.length >= kMaxPlayers
                          ? null
                          : _addPlayer,
                      icon: const Icon(Icons.add),
                      label: const Text('Add player'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _themeSection(themes),
                  const SizedBox(height: 24),
                  SectionLabel('Imposters'),
                  const SizedBox(height: 4),
                  Text(
                    'Suggested: ${suggestImposterCount(_nameControllers.length)} '
                    '(max $maxAllowed)',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  _imposterStepper(maxAllowed),
                  const SizedBox(height: 20),
                  _secretRolesCard(),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lavender,
                      foregroundColor: AppColors.onLavender,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Game'),
                    onPressed: _start,
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: AppTab.play,
        onTap: (tab) {
          switch (tab) {
            case AppTab.lobby:
              Navigator.of(context).maybePop();
            case AppTab.play:
              break;
            case AppTab.rules:
              showHowToPlay(context);
          }
        },
      ),
    );
  }

  GameTheme _initialTheme(List<GameTheme> themes) {
    if (widget.initialThemeName != null) {
      for (final t in themes) {
        if (t.name == widget.initialThemeName) return t;
      }
    }
    return themes.first;
  }

  Widget _themeSection(List<GameTheme> themes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Theme'),
                const SizedBox(height: 6),
                Text(_selectedTheme?.name ?? '',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cyan),
                      ),
                      child: const Text('ACTIVE',
                          style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _pickTheme(themes),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        child: const Text('CHANGE',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.category_outlined,
              color: Colors.white.withValues(alpha: 0.3), size: 32),
        ],
      ),
    );
  }

  Widget _imposterStepper(int maxAllowed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(
          Icons.remove,
          _imposterCount > 1 ? () => setState(() => _imposterCount--) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text('$_imposterCount',
              style: const TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800)),
        ),
        _circleButton(
          Icons.add,
          _imposterCount < maxAllowed
              ? () => setState(() => _imposterCount++)
              : null,
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cardFill,
            border: Border.all(
              color: enabled ? AppColors.primary : AppColors.cardBorder,
            ),
          ),
          child: Icon(icon,
              color: enabled ? Colors.white : Colors.white24),
        ),
      ),
    );
  }

  Widget _secretRolesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secret Roles',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Roles will be hidden until the game starts',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chat_bubble_outline,
              color: AppColors.magentaA.withValues(alpha: 0.8)),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerFields() {
    return [
      for (var i = 0; i < _nameControllers.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: _nameControllers[i],
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline),
              hintText: 'Player ${i + 1}',
              suffixIcon: IconButton(
                onPressed: _nameControllers.length <= kMinPlayers
                    ? null
                    : () => _removePlayer(i),
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ),
    ];
  }
}
