import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/online_providers.dart';
import '../../../data/online/online_models.dart';
import '../../../domain/models/enums.dart';
import '../../widgets/gradient_background.dart';

/// The synced online game. Every device watches the same Firestore room and
/// renders the view for the current phase. Only the host sees "advance"
/// buttons; everyone else sees a waiting message.
class OnlineGameScreen extends ConsumerWidget {
  const OnlineGameScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomStreamProvider(code));
    final membersAsync = ref.watch(membersStreamProvider(code));
    final uid = ref.watch(authUidProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Imposter — Online'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: roomAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (room) {
              final members = membersAsync.value ?? const [];
              final isHost = room.hostId == uid;
              switch (room.phase) {
                case GamePhase.roleReveal:
                  return _RoleRevealOnline(code: code, isHost: isHost);
                case GamePhase.clue:
                  return _CluePhaseOnline(
                      code: code, room: room, members: members, isHost: isHost);
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
          onPressed: () => repo.setPhase(code, GamePhase.clue),
          waitingText: 'Remember your role. Waiting for the host…',
        ),
      ],
    );
  }
}

// ---- Clue phase -----------------------------------------------------------

class _CluePhaseOnline extends ConsumerWidget {
  const _CluePhaseOnline({
    required this.code,
    required this.room,
    required this.members,
    required this.isHost,
  });
  final String code;
  final OnlineRoom room;
  final List<OnlineMember> members;
  final bool isHost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(roomRepositoryProvider);
    // Members already arrive sorted by join time; just keep the living ones.
    final ordered = members.where((m) => m.isAlive).toList();

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
                  const Text(
                      'Say ONE short clue out loud, in order. Don\'t say the word!',
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: ordered.length,
            itemBuilder: (_, i) => ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(ordered[i].name),
            ),
          ),
        ),
        _HostControls(
          isHost: isHost,
          label: 'Open Voting',
          icon: Icons.how_to_vote,
          onPressed: () => repo.openVoting(code),
        ),
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
    required this.selected,
    required this.onPressed,
  });

  final String name;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = Text(name, style: const TextStyle(fontSize: 18));
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
