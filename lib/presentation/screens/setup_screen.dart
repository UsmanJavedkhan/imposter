import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/game_providers.dart';
import '../../domain/engine/imposter_rules.dart';
import '../../domain/models/game_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/ui_kit.dart';
import 'game_screen.dart';
import 'home_screen.dart' show showHowToPlay, themeIcon;

/// Lets the host add players, pick a theme, and choose the imposter count.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key, this.initialThemeName});

  /// Optional theme to pre-select (e.g. from the home "All Themes" grid).
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
                leading: _ThemeCircle(themeId: t.id, icon: themeIcon(t.id)),
                title: Text(t.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                subtitle: Text('${t.words.length} words',
                    style: const TextStyle(color: AppColors.textSecondary)),
                trailing: t.id == _selectedTheme?.id
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const BrandWordmark(fontSize: 18, letterSpacing: 2),
      ),
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
                  // --- Title ---------------------------------------------
                  Text('Game Setup',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  const Text('Prepare for the mystery',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 24),

                  // --- Players section -----------------------------------
                  Row(
                    children: [
                      const Icon(Icons.groups,
                          color: AppColors.cyan, size: 18),
                      const SizedBox(width: 6),
                      SectionLabel(
                          'Players (${_nameControllers.length})',
                          color: AppColors.cyan),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._buildPlayerCards(),
                  _AddPlayerCard(
                    onTap: _nameControllers.length >= kMaxPlayers
                        ? null
                        : _addPlayer,
                  ),
                  const SizedBox(height: 22),

                  // --- Theme section -------------------------------------
                  Row(
                    children: const [
                      Icon(Icons.palette_outlined,
                          color: AppColors.cyan, size: 18),
                      SizedBox(width: 6),
                      SectionLabel('Theme'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _themeCard(themes),
                  const SizedBox(height: 22),

                  // --- Imposters counter ---------------------------------
                  Row(
                    children: const [
                      Icon(Icons.theater_comedy,
                          color: AppColors.primary, size: 18),
                      SizedBox(width: 6),
                      SectionLabel('Imposters', color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Suggested: ${suggestImposterCount(_nameControllers.length)} '
                      '(max $maxAllowed)',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 14),
                  _imposterStepper(maxAllowed),

                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: lavenderButtonStyle(),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Game'),
                      onPressed: _start,
                    ),
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

  Widget _themeCard(List<GameTheme> themes) {
    final theme = _selectedTheme!;
    // The whole card is now a single tap target — tapping anywhere on the
    // row (icon, name, ACTIVE / CHANGE chips, the trailing shapes glyph)
    // opens the picker. Material's InkWell provides the touch ripple.
    return Material(
      color: AppColors.cardFill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _pickTheme(themes),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
        children: [
          _ThemeCircle(themeId: theme.id, icon: themeIcon(theme.id), size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(theme.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cyan, width: 1.2),
                      ),
                      child: const Text('ACTIVE',
                          style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(width: 8),
                    // CHANGE remains a visible affordance — it shares the
                    // same tap because the parent InkWell handles the gesture.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.bgMid,
                      ),
                      child: const Text('CHANGE',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.category_outlined,
              color: AppColors.textTertiary.withValues(alpha: 0.6), size: 28),
        ],
      ),
        ),
      ),
    );
  }

  Widget _imposterStepper(int maxAllowed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepperButton(
          Icons.remove,
          _imposterCount > 1 ? () => setState(() => _imposterCount--) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text('$_imposterCount',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
        ),
        _stepperButton(
          Icons.add,
          _imposterCount < maxAllowed
              ? () => setState(() => _imposterCount++)
              : null,
        ),
      ],
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.bgMid,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon,
              color:
                  enabled ? AppColors.primary : AppColors.textTertiary,
              size: 24),
        ),
      ),
    );
  }

  List<Widget> _buildPlayerCards() {
    return [
      for (var i = 0; i < _nameControllers.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PlayerRow(
            controller: _nameControllers[i],
            index: i,
            canRemove: _nameControllers.length > kMinPlayers,
            onRemove: () => _removePlayer(i),
          ),
        ),
    ];
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.controller,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  final TextEditingController controller;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            child: const Icon(Icons.person_outline,
                color: AppColors.cyan, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'Player ${index + 1}',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            onPressed: canRemove ? onRemove : null,
            tooltip: 'Remove',
            icon: Icon(Icons.close,
                color: canRemove ? AppColors.primary : AppColors.textTertiary,
                size: 22),
          ),
        ],
      ),
    );
  }
}

class _AddPlayerCard extends StatelessWidget {
  const _AddPlayerCard({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? AppColors.cyan : AppColors.textTertiary;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: DottedBorderBox(
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: color, size: 20),
              const SizedBox(width: 8),
              Text('Add player',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick dashed-border container (no extra package required).
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child, required this.color});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const radius = Radius.circular(14);
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), radius);
    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final m in path.computeMetrics()) {
      double distance = 0;
      while (distance < m.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
            m.extractPath(distance, next.clamp(0, m.length)), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color;
}

class _ThemeCircle extends StatelessWidget {
  const _ThemeCircle({
    required this.themeId,
    required this.icon,
    this.size = 40,
  });

  final String themeId;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.themeTileColors(themeId);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: fg, size: size * 0.5),
    );
  }
}

