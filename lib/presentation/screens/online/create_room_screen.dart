import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/game_providers.dart';
import '../../../application/online_providers.dart';
import '../../../domain/engine/imposter_rules.dart';
import '../../../domain/models/game_theme.dart';
import '../../widgets/gradient_background.dart';
import 'lobby_screen.dart';

/// Host configures and creates a room.
class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key, required this.playerName});
  final String playerName;

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  GameTheme? _theme;
  int _imposterCount = 1;
  bool _creating = false;

  Future<void> _create() async {
    if (_theme == null) return;
    setState(() => _creating = true);
    try {
      final uid = await ref.read(authUidProvider.future);
      final code = await ref.read(roomRepositoryProvider).createRoom(
            uid: uid,
            hostName: widget.playerName,
            themeName: _theme!.name,
            imposterCount: _imposterCount,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LobbyScreen(code: code)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themesAsync = ref.watch(themesProvider);
    // For online we allow up to the same max; imposter count is chosen now but
    // re-validated against the real player count when the host starts.
    const maxAllowed = 4;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Room')),
      body: themesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load themes:\n$e')),
        data: (themes) {
          _theme ??= themes.first;
          return GradientBackground(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Theme', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<GameTheme>(
                  initialValue: _theme,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), filled: true),
                  items: [
                    for (final t in themes)
                      DropdownMenuItem(value: t, child: Text(t.name)),
                  ],
                  onChanged: (t) => setState(() => _theme = t),
                ),
                const SizedBox(height: 24),
                Text('Imposters', style: Theme.of(context).textTheme.titleLarge),
                const Text('You can adjust before starting.',
                    style: TextStyle(color: Colors.white70)),
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
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: _creating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(_creating ? 'Creating…' : 'Create Room'),
                  onPressed: _creating ? null : _create,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Minimum $kMinPlayers players needed to start.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
