import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/game_providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/word_hint.dart';
import '../widgets/gradient_background.dart';
import '../widgets/hint_chip.dart';

/// Shows the right view for the current game phase. Because the engine drives
/// [GamePhase], this single screen handles the whole play loop.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    final game = session.game;

    if (game == null) {
      return const Scaffold(body: Center(child: Text('No game in progress.')));
    }

    switch (game.phase) {
      case GamePhase.roleReveal:
        return _RoleRevealView(game: game, revealIndex: session.revealIndex);
      case GamePhase.clue:
        return _ClueView(game: game);
      case GamePhase.voting:
        return _VotingView(game: game);
      case GamePhase.reveal:
      case GamePhase.gameOver:
        return _ResultView(game: game);
      case GamePhase.lobby:
        return const Scaffold(body: Center(child: Text('Setting up…')));
    }
  }
}

// ---------------------------------------------------------------------------
// Role reveal (pass-and-play)
// ---------------------------------------------------------------------------

class _RoleRevealView extends ConsumerWidget {
  const _RoleRevealView({required this.game, required this.revealIndex});

  final GameState game;
  final int revealIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);

    // Everyone has seen their role -> ready to start clues.
    if (revealIndex >= game.players.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ready')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 80, color: Colors.green),
                const SizedBox(height: 16),
                Text('Everyone has seen their role!',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Now take turns saying a one-word clue out loud.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),
                FilledButton.icon(
                  icon: const Icon(Icons.record_voice_over),
                  label: const Text('Start Clues'),
                  onPressed: controller.beginClues,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final player = game.players[revealIndex];
    // The key resets the inner "revealed?" state each time the player changes.
    return _RoleCard(
      key: ValueKey(revealIndex),
      player: player,
      themeName: game.config.themeName,
      secretWord: game.secretWord,
      onDone: controller.nextReveal,
    );
  }
}

/// A single player's private reveal: tap a card that flips to show the role,
/// then hide and pass to the next player.
class _RoleCard extends StatefulWidget {
  const _RoleCard({
    super.key,
    required this.player,
    required this.themeName,
    required this.secretWord,
    required this.onDone,
  });

  final Player player;
  final String themeName;
  final String secretWord;
  final VoidCallback onDone;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  bool get _revealed => _flip.value > 0.5;

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _reveal() {
    if (!_flip.isAnimating && _flip.value == 0) _flip.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isImposter = widget.player.isImposter;

    // Background tint stays neutral until revealed, then hints the role.
    return AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final showFront = _flip.value > 0.5;
        final List<Color> bg = !showFront
            ? const [Color(0xFF1A1033), Color(0xFF2A1A5E), Color(0xFF3A1C71)]
            : (isImposter
                ? const [Color(0xFF3A0D0D), Color(0xFF5E1A1A), Color(0xFF7A1C1C)]
                : const [Color(0xFF0D2E1A), Color(0xFF14512A), Color(0xFF1C7137)]);

        return Scaffold(
          appBar: AppBar(
            title: Text('Pass to ${widget.player.name}'),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
          ),
          extendBodyBehindAppBar: true,
          body: GradientBackground(
            colors: bg,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _revealed ? null : _reveal,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(_flip.value * math.pi),
                          child: showFront
                              // The widget is mirrored at >90°, so flip the
                              // front content back so text isn't reversed.
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..rotateY(math.pi),
                                  child: _front(isImposter),
                                )
                              : _back(),
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_revealed)
                        FilledButton.icon(
                          icon: const Icon(Icons.visibility_off),
                          label: const Text('Hide & Pass'),
                          onPressed: widget.onDone,
                        )
                      else
                        Text('Tap the card to reveal',
                            style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cardShell({required Widget child, Color? color}) {
    return Container(
      width: 280,
      height: 360,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Center(child: child),
    );
  }

  Widget _back() {
    return _cardShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.help_outline, size: 72, color: Colors.white70),
          const SizedBox(height: 16),
          Text(widget.player.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Don't let others see!"),
        ],
      ),
    );
  }

  Widget _front(bool isImposter) {
    if (isImposter) {
      return _cardShell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.theater_comedy, size: 72, color: Colors.white),
            const SizedBox(height: 16),
            const Text('YOU ARE THE\nIMPOSTER',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 16),
            Text('Theme: ${widget.themeName}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            HintChip(text: buildImposterHint(widget.secretWord)),
            const SizedBox(height: 8),
            const Text('Blend in — you do NOT know the word.',
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return _cardShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('The secret word is'),
          const SizedBox(height: 12),
          Text(widget.secretWord,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Theme: ${widget.themeName}',
              style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Clue phase (clues are spoken out loud; we just show the order)
// ---------------------------------------------------------------------------

class _ClueView extends ConsumerWidget {
  const _ClueView({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);
    final order = game.alivePlayers;
    return Scaffold(
      appBar: AppBar(title: Text('Round ${game.roundNumber} — Clues')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Theme: ${game.config.themeName}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('Go in order. Say ONE short clue about the word. '
                        'Don\'t say the word itself!',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: order.length,
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(order[i].name),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: const Icon(Icons.how_to_vote),
                label: const Text('Everyone gave a clue — Vote'),
                onPressed: controller.openVoting,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Voting (tap the player the group decided to eliminate)
// ---------------------------------------------------------------------------

class _VotingView extends ConsumerWidget {
  const _VotingView({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);
    final alive = game.alivePlayers;

    Future<void> confirm(String? id, String label) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirm vote'),
          content: Text(id == null
              ? 'Skip elimination this round (tie)?'
              : 'Vote out $label?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm')),
          ],
        ),
      );
      if (ok == true) controller.eliminate(id);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Vote')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Discuss, then tap who the group votes out.',
                style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final p in alive)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18)),
                        onPressed: () => confirm(p.id, p.name),
                        child: Text(p.name,
                            style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => confirm(null, ''),
                  child: const Text('Tie / Skip — nobody out'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result of a vote / end of game
// ---------------------------------------------------------------------------

class _ResultView extends ConsumerWidget {
  const _ResultView({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);
    final eliminated = game.lastEliminatedId == null
        ? null
        : game.playerById(game.lastEliminatedId!);

    final isOver = game.isGameOver;
    final civiliansWon = game.winner == Role.civilian;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOver ? 'Game Over' : 'Vote Result'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (eliminated == null)
                const Text('It was a tie — nobody was eliminated.',
                    style: TextStyle(fontSize: 18), textAlign: TextAlign.center)
              else
                Column(
                  children: [
                    Text('${eliminated.name} was voted out',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(eliminated.isImposter
                          ? 'They were an IMPOSTER'
                          : 'They were a CIVILIAN'),
                      backgroundColor: eliminated.isImposter
                          ? Colors.red.shade900
                          : Colors.green.shade900,
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              if (isOver) ...[
                Icon(civiliansWon ? Icons.verified_user : Icons.theater_comedy,
                    size: 72,
                    color: civiliansWon ? Colors.greenAccent : Colors.redAccent),
                const SizedBox(height: 8),
                Text(civiliansWon ? 'CIVILIANS WIN!' : 'IMPOSTERS WIN!',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _RoleSummary(game: game),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                  onPressed: () {
                    controller.reset();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
              ] else
                FilledButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next Round'),
                  onPressed: controller.nextRound,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows everyone's true role at the end of the game.
class _RoleSummary extends StatelessWidget {
  const _RoleSummary({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in game.players)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    p.isImposter ? Icons.theater_comedy : Icons.verified_user,
                    size: 18,
                    color: p.isImposter ? Colors.redAccent : Colors.greenAccent,
                  ),
                  const SizedBox(width: 8),
                  Text('${p.name} — ${p.isImposter ? 'Imposter' : 'Civilian'}'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
