import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../application/game_providers.dart';
import '../../../application/online_providers.dart';
import '../../../application/presence.dart';
import '../../../domain/engine/imposter_rules.dart';
import '../../widgets/gradient_background.dart';
import 'online_game_screen.dart';

/// Waiting room. Shows the code and members; the host starts the game.
class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen>
    with WidgetsBindingObserver, RoomPresenceMixin {
  @override
  String get roomCode => widget.code;

  @override
  void initState() {
    super.initState();
    startPresence();
  }

  @override
  void dispose() {
    stopPresence();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      handleLifecycle(state);

  Future<void> _leave() async {
    final uid = ref.read(authUidProvider).value;
    if (uid != null) {
      await ref.read(roomRepositoryProvider).leave(widget.code, uid);
    }
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _start(int playerCount, String themeName, int imposterCount) async {
    if (playerCount < kMinPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Need at least $kMinPlayers players.')),
      );
      return;
    }
    if (!isValidImposterCount(playerCount, imposterCount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            'Too many imposters for $playerCount players '
            '(max ${maxImposters(playerCount)}).')),
      );
      return;
    }
    try {
      final themes = await ref.read(themesProvider.future);
      final theme = themes.firstWhere((t) => t.name == themeName,
          orElse: () => themes.first);
      final word = ref.read(wordRepositoryProvider).randomWord(theme);
      await ref
          .read(roomRepositoryProvider)
          .startGame(code: widget.code, secretWord: word);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to start: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.code;
    final roomAsync = ref.watch(roomStreamProvider(code));
    final membersAsync = ref.watch(membersStreamProvider(code));
    final uid = ref.watch(authUidProvider).value;

    // When the game starts, move everyone to the game screen.
    ref.listen(roomStreamProvider(code), (prev, next) {
      final room = next.value;
      if (room != null && room.phase.name != 'lobby') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => OnlineGameScreen(code: code)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Leave room',
            onPressed: _leave,
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: roomAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (room) {
              // Promote a new host if the original one left the lobby.
              maybeMigrateHost(room, membersAsync.value ?? const []);
              final isHost = room.hostId == uid;
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Room Code',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied!')),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(code,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 8)),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy, size: 20),
                        ],
                      ),
                    ),
                    Text('Theme: ${room.themeName}  •  Imposters: ${room.imposterCount}',
                        style: const TextStyle(color: Colors.white70)),
                    const Divider(height: 32),
                    Expanded(
                      child: membersAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (members) => ListView(
                          children: [
                            Text('Players (${members.length})',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            for (final m in members)
                              ListTile(
                                leading: CircleAvatar(
                                    child: Text(m.name.isNotEmpty
                                        ? m.name[0].toUpperCase()
                                        : '?')),
                                title: Text(m.name),
                                trailing: m.uid == room.hostId
                                    ? const Chip(label: Text('Host'))
                                    : (m.isConnected
                                        ? null
                                        : const Icon(Icons.wifi_off,
                                            color: Colors.orange)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (isHost)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16)),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Game'),
                          onPressed: () => _start(
                            membersAsync.value?.length ?? 0,
                            room.themeName,
                            room.imposterCount,
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Waiting for the host to start…',
                            style: TextStyle(color: Colors.white70)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
