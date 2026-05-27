import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../application/game_providers.dart';
import '../../../application/online_providers.dart';
import '../../../application/presence.dart';
import '../../../domain/engine/imposter_rules.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/ui_kit.dart';
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

  Future<void> _start(
      int playerCount, String themeName, int imposterCount) async {
    if (playerCount < kMinPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Need at least $kMinPlayers players.')),
      );
      return;
    }
    if (!isValidImposterCount(playerCount, imposterCount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Too many imposters for $playerCount players '
                '(max ${maxImposters(playerCount)}).')),
      );
      return;
    }
    try {
      final themes = await ref.read(themesProvider.future);
      final theme = themes.firstWhere((t) => t.name == themeName,
          orElse: () => themes.first);
      final word = ref.read(wordRepositoryProvider).randomWord(theme);
      await ref.read(roomRepositoryProvider).startGame(
            code: widget.code,
            secretWord: word,
            hintWord: theme.hintFor(word),
          );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const BrandWordmark(fontSize: 18, letterSpacing: 2),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primary),
            tooltip: 'Leave room',
            onPressed: _leave,
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: roomAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: const TextStyle(color: AppColors.textPrimary)),
            ),
            data: (room) {
              maybeMigrateHost(room, membersAsync.value ?? const []);
              final isHost = room.hostId == uid;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    // --- Room code card ----------------------------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.cardFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        children: [
                          const Text('ROOM CODE',
                              style: TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4)),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Code copied!')),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(code,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 8,
                                      color: AppColors.textPrimary,
                                    )),
                                const SizedBox(width: 8),
                                const Icon(Icons.copy,
                                    size: 18,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'Theme: ${room.themeName}  •  Imposters: ${room.imposterCount}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // --- Players section --------------------------------
                    Expanded(
                      child: membersAsync.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                            child: Text('Error: $e',
                                style: const TextStyle(
                                    color: AppColors.textPrimary))),
                        data: (members) => ListView(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.groups,
                                    color: AppColors.cyan, size: 18),
                                const SizedBox(width: 6),
                                SectionLabel(
                                    'Players (${members.length})'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            for (final m in members)
                              _PlayerListTile(
                                name: m.name,
                                isHost: m.uid == room.hostId,
                                isConnected: m.isConnected,
                                isMe: m.uid == uid,
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (isHost)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: lavenderButtonStyle(),
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
                            style: TextStyle(
                                color: AppColors.textSecondary)),
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

class _PlayerListTile extends StatelessWidget {
  const _PlayerListTile({
    required this.name,
    required this.isHost,
    required this.isConnected,
    required this.isMe,
  });

  final String name;
  final bool isHost;
  final bool isConnected;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.cyan, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(isMe ? '$name (you)' : name,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700)),
            ),
            if (isHost)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: const Text('Host',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6)),
              )
            else if (!isConnected)
              const Icon(Icons.wifi_off,
                  color: AppColors.amberHint, size: 18),
          ],
        ),
      ),
    );
  }
}
