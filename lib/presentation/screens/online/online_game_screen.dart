import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/online_providers.dart';
import '../../../application/presence.dart';
import '../../../data/online/online_models.dart';
import '../../../domain/models/enums.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/hint_chip.dart';

/// The synced online game. Every device watches the same Firestore room and
/// renders the view for the current phase. Only the host sees "advance"
/// buttons; everyone else sees a waiting message.
class OnlineGameScreen extends ConsumerStatefulWidget {
  const OnlineGameScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen>
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

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave game?'),
        content: const Text('You will drop out of this round.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave')),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.code;
    final roomAsync = ref.watch(roomStreamProvider(code));
    final membersAsync = ref.watch(membersStreamProvider(code));
    final uid = ref.watch(authUidProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Imposter — Online'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Leave game',
            onPressed: _confirmLeave,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: roomAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (room) {
              final members = membersAsync.value ?? const [];
              // Keep a host alive even if the original one disappears.
              maybeMigrateHost(room, members);
              final isHost = room.hostId == uid;
              switch (room.phase) {
                case GamePhase.roleReveal:
                  return _RoleRevealOnline(code: code, isHost: isHost);
                case GamePhase.clue:
                  return _CluePhaseOnline(
                      code: code,
                      room: room,
                      members: members,
                      uid: uid,
                      isHost: isHost);
                case GamePhase.voting:
                  return _VotingOnline(
                      code: code, members: members, uid: uid, isHost: isHost);
                case GamePhase.reveal:
                  return _RevealOnline(
                      room: room, members: members, isHost: isHost, code: code);
                case GamePhase.gameOver:
                  return _GameOverOnline(room: room, members: members);
                case GamePhase.lobby:
                  return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Shared little "waiting for host" footer.
class _HostControls extends StatelessWidget {
  const _HostControls({
    required this.isHost,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.waitingText = 'Waiting for the host…',
  });

  final bool isHost;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final String waitingText;

  @override
  Widget build(BuildContext context) {
    if (!isHost) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(waitingText, style: const TextStyle(color: Colors.white70)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style:
              FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          icon: Icon(icon),
          label: Text(label),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

// ---- Role reveal ----------------------------------------------------------

class _RoleRevealOnline extends ConsumerWidget {
  const _RoleRevealOnline({required this.code, required this.isHost});
  final String code;
  final bool isHost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(myRoleStreamProvider(code));
    final repo = ref.read(roomRepositoryProvider);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: roleAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (role) {
                if (role == null) {
                  return const CircularProgressIndicator();
                }
                final imposter = role.isImposter;
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        imposter ? Icons.theater_comedy : Icons.verified_user,
                        size: 88,
                        color: imposter ? Colors.redAccent : Colors.greenAccent,
                      ),
                      const SizedBox(height: 16),
                      if (imposter) ...[
                        const Text('YOU ARE THE IMPOSTER',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text('Theme: ${role.themeName}',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        HintChip(text: role.hint ?? ''),
                        const SizedBox(height: 8),
                        const Text('Blend in — you do NOT know the word.',
                            textAlign: TextAlign.center),
                      ] else ...[
                        const Text('The secret word is'),
                        const SizedBox(height: 8),
                        Text(role.secretWord ?? '',
                            style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text('Theme: ${role.themeName}',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        _HostControls(
          isHost: isHost,
          label: 'Start Clues',
          icon: Icons.record_voice_over,
          onPressed: () => repo.beginCluePhase(code),
          waitingText: 'Remember your role. Waiting for the host…',
        ),
      ],
    );
  }
}

// ---- Clue phase -----------------------------------------------------------

class _CluePhaseOnline extends ConsumerStatefulWidget {
  const _CluePhaseOnline({
    required this.code,
    required this.room,
    required this.members,
    required this.uid,
    required this.isHost,
  });
  final String code;
  final OnlineRoom room;
  final List<OnlineMember> members;
  final String? uid;
  final bool isHost;

  @override
  ConsumerState<_CluePhaseOnline> createState() => _CluePhaseOnlineState();
}

class _CluePhaseOnlineState extends ConsumerState<_CluePhaseOnline> {
  final _controller = TextEditingController();

  /// Drives the countdown display and (on the host) turn advancement.
  Timer? _ticker;

  /// Guards against firing overlapping advance writes while one is in flight.
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {}); // refresh the countdown
      _maybeAdvance();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// HOST ONLY. Advances the turn once the current player has submitted a clue
  /// or their countdown has run out.
  Future<void> _maybeAdvance() async {
    if (!widget.isHost || _advancing) return;
    final turnUid = widget.room.currentTurnUid;
    if (turnUid == null) return;

    final current =
        widget.members.where((m) => m.uid == turnUid).firstOrNull;
    final submitted = current?.clue != null;
    final deadline = widget.room.turnDeadline;
    final expired = deadline != null && DateTime.now().isAfter(deadline);

    if (submitted || expired) {
      _advancing = true;
      try {
        await ref.read(roomRepositoryProvider).advanceClueTurn(widget.code);
      } finally {
        _advancing = false;
      }
    }
  }

  int _secondsLeft() {
    final deadline = widget.room.turnDeadline;
    if (deadline == null) return 0;
    final s = deadline.difference(DateTime.now()).inSeconds;
    return s < 0 ? 0 : s;
  }

  void _submit(String? secretWord) {
    final text = _controller.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (text.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Clue cannot be empty.')));
      return;
    }
    if (secretWord != null &&
        text.toLowerCase().contains(secretWord.toLowerCase())) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Your clue cannot contain the secret word.')));
      return;
    }
    ref.read(roomRepositoryProvider).submitClue(widget.code, widget.uid!, text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(roomRepositoryProvider);
    final room = widget.room;
    final ordered = widget.members.where((m) => m.isAlive).toList();
    final turnUid = room.currentTurnUid;
    final allCluesIn = turnUid == null;
    final isMyTurn = widget.uid != null && widget.uid == turnUid;
    final me = widget.members.where((m) => m.uid == widget.uid).firstOrNull;
    final iSubmitted = me?.clue != null;
    final secretWord = ref.watch(myRoleStreamProvider(widget.code)).value?.secretWord;
    final secondsLeft = _secondsLeft();
    final turnName =
        widget.members.where((m) => m.uid == turnUid).firstOrNull?.name;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Round ${room.roundNumber}  •  Theme: ${room.themeName}',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  if (allCluesIn)
                    const Text('All clues are in. Time to vote!',
                        textAlign: TextAlign.center)
                  else ...[
                    Text(
                        isMyTurn
                            ? 'Your turn — type ONE word. Don\'t use the secret word!'
                            : '${turnName ?? 'Someone'} is giving a clue…',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    _Countdown(seconds: secondsLeft),
                  ],
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: ordered.length,
            itemBuilder: (_, i) {
              final m = ordered[i];
              final isTurn = m.uid == turnUid;
              final isMe = m.uid == widget.uid;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isTurn ? Colors.amber.shade700 : null,
                  child: Text('${i + 1}'),
                ),
                title: Text(isMe ? '${m.name} (you)' : m.name),
                trailing: m.clue != null
                    ? Chip(label: Text(m.clue!))
                    : Text(isTurn ? 'typing…' : 'waiting',
                        style: const TextStyle(color: Colors.white54)),
              );
            },
          ),
        ),
        if (isMyTurn && !iSubmitted)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(secretWord),
                    decoration: const InputDecoration(
                      hintText: 'Your one-word clue',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _submit(secretWord),
                  child: const Text('Send'),
                ),
              ],
            ),
          )
        else if (!allCluesIn && !isMyTurn)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Wait for your turn…',
                style: TextStyle(color: Colors.white70)),
          ),
        _HostControls(
          isHost: widget.isHost,
          label: 'Open Voting',
          icon: Icons.how_to_vote,
          onPressed: () => repo.openVoting(widget.code),
          waitingText: allCluesIn
              ? 'Waiting for the host to open voting…'
              : 'Waiting for clues…',
        ),
      ],
    );
  }
}

/// Big circular countdown for the current clue turn.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= 5;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer,
            size: 20, color: urgent ? Colors.redAccent : Colors.white70),
        const SizedBox(width: 6),
        Text('${seconds}s',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: urgent ? Colors.redAccent : Colors.white,
            )),
      ],
    );
  }
}

// ---- Voting ---------------------------------------------------------------

class _VotingOnline extends ConsumerWidget {
  const _VotingOnline({
    required this.code,
    required this.members,
    required this.uid,
    required this.isHost,
  });
  final String code;
  final List<OnlineMember> members;
  final String? uid;
  final bool isHost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(roomRepositoryProvider);
    final alive = members.where((m) => m.isAlive).toList();
    final me = members.where((m) => m.uid == uid).firstOrNull;
    final myVote = me?.voteTargetId;
    final iAmAlive = me?.isAlive ?? false;
    final votesIn = alive.where((m) => m.voteTargetId != null).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Vote out the imposter  ($votesIn/${alive.length} voted)',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final m in alive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: _VoteButton(
                      name: m.name,
                      clue: m.clue,
                      selected: myVote == m.uid,
                      onPressed: (iAmAlive && uid != null)
                          ? () => repo.castVote(code, uid!, m.uid)
                          : null,
                    ),
                  ),
                ),
              if (!iAmAlive)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('You were eliminated — watch the rest!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70)),
                ),
            ],
          ),
        ),
        _HostControls(
          isHost: isHost,
          label: 'Reveal Results',
          icon: Icons.gavel,
          onPressed: () => repo.resolveVotes(code),
          waitingText: 'Cast your vote. Waiting for the host to reveal…',
        ),
      ],
    );
  }
}

/// A single vote target. Filled when it's your current pick, outlined otherwise.
class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.name,
    required this.clue,
    required this.selected,
    required this.onPressed,
  });

  final String name;
  final String? clue;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: const TextStyle(fontSize: 18)),
        Text(
          clue == null || clue!.isEmpty ? '(no clue given)' : 'Clue: "$clue"',
          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
        ),
      ],
    );
    final icon = Icon(selected ? Icons.check_circle : Icons.person);
    final padding =
        const EdgeInsets.symmetric(vertical: 16);
    if (selected) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(padding: padding),
        icon: icon,
        label: label,
        onPressed: onPressed,
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(padding: padding),
      icon: icon,
      label: label,
      onPressed: onPressed,
    );
  }
}

// ---- Reveal (between rounds) ----------------------------------------------

class _RevealOnline extends ConsumerWidget {
  const _RevealOnline({
    required this.room,
    required this.members,
    required this.isHost,
    required this.code,
  });
  final OnlineRoom room;
  final List<OnlineMember> members;
  final bool isHost;
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(roomRepositoryProvider);
    final eliminated = room.lastEliminatedId == null
        ? null
        : members.where((m) => m.uid == room.lastEliminatedId).firstOrNull;
    final wasImposter = room.lastEliminatedRole == Role.imposter;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: eliminated == null
                  ? const Text('It was a tie — nobody was eliminated.',
                      style: TextStyle(fontSize: 20), textAlign: TextAlign.center)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${eliminated.name} was voted out',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Chip(
                          label: Text(wasImposter
                              ? 'They were an IMPOSTER'
                              : 'They were a CIVILIAN'),
                          backgroundColor: wasImposter
                              ? Colors.red.shade900
                              : Colors.green.shade900,
                        ),
                      ],
                    ),
            ),
          ),
        ),
        _HostControls(
          isHost: isHost,
          label: 'Next Round',
          icon: Icons.arrow_forward,
          onPressed: () => repo.nextRound(code),
        ),
      ],
    );
  }
}

// ---- Game over ------------------------------------------------------------

class _GameOverOnline extends StatelessWidget {
  const _GameOverOnline({required this.room, required this.members});
  final OnlineRoom room;
  final List<OnlineMember> members;

  @override
  Widget build(BuildContext context) {
    final civiliansWon = room.winner == Role.civilian;
    final nameById = {for (final m in members) m.uid: m.name};

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(civiliansWon ? Icons.verified_user : Icons.theater_comedy,
                size: 80,
                color: civiliansWon ? Colors.greenAccent : Colors.redAccent),
            const SizedBox(height: 12),
            Text(civiliansWon ? 'CIVILIANS WIN!' : 'IMPOSTERS WIN!',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (room.revealedSecretWord != null)
              Text('The word was "${room.revealedSecretWord}"',
                  style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final entry in room.revealedRoles.entries)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            entry.value == Role.imposter.name
                                ? Icons.theater_comedy
                                : Icons.verified_user,
                            size: 18,
                            color: entry.value == Role.imposter.name
                                ? Colors.redAccent
                                : Colors.greenAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                              '${nameById[entry.key] ?? 'Player'} — '
                              '${entry.value == Role.imposter.name ? 'Imposter' : 'Civilian'}'),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}
