import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/game_providers.dart';
import '../../domain/engine/imposter_rules.dart';
import '../../domain/models/game_theme.dart';
import 'game_screen.dart';

/// Lets the host add players, pick a theme, and choose the imposter count.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final themesAsync = ref.watch(themesProvider);
    final maxAllowed = maxImposters(_nameControllers.length);

    return Scaffold(
      appBar: AppBar(title: const Text('Game Setup')),
      body: themesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load themes:\n$e')),
        data: (themes) {
          _selectedTheme ??= themes.first;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Players (${_nameControllers.length})',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._buildPlayerFields(),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _nameControllers.length >= kMaxPlayers
                      ? null
                      : _addPlayer,
                  icon: const Icon(Icons.add),
                  label: const Text('Add player'),
                ),
              ),
              const Divider(height: 32),
              Text('Theme', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<GameTheme>(
                initialValue: _selectedTheme,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  for (final t in themes)
                    DropdownMenuItem(value: t, child: Text(t.name)),
                ],
                onChanged: (t) => setState(() => _selectedTheme = t),
              ),
              const Divider(height: 32),
              Text('Imposters', style: Theme.of(context).textTheme.titleLarge),
              Text('Suggested: ${suggestImposterCount(_nameControllers.length)} '
                  '(max $maxAllowed)',
                  style: Theme.of(context).textTheme.bodySmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: _imposterCount > 1
                        ? () => setState(() => _imposterCount--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('$_imposterCount',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  IconButton.filledTonal(
                    onPressed: _imposterCount < maxAllowed
                        ? () => setState(() => _imposterCount++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Game'),
                onPressed: _start,
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildPlayerFields() {
    return [
      for (var i = 0; i < _nameControllers.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameControllers[i],
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                    labelText: 'Player ${i + 1}',
                  ),
                ),
              ),
              IconButton(
                onPressed: _nameControllers.length <= kMinPlayers
                    ? null
                    : () => _removePlayer(i),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
    ];
  }
}
