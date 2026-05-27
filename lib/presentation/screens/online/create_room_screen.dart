import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/game_providers.dart';
import '../../../application/online_providers.dart';
import '../../../domain/engine/imposter_rules.dart';
import '../../../domain/models/game_theme.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/ui_kit.dart';
import '../home_screen.dart' show themeIcon;
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
                leading: _ThemeCircle(
                    themeId: t.id, icon: themeIcon(t.id)),
                title: Text(t.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                subtitle: Text('${t.words.length} words',
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
                trailing: t.id == _theme?.id
                    ? const Icon(Icons.check_circle,
                        color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, t),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _theme = picked);
  }

  @override
  Widget build(BuildContext context) {
    final themesAsync = ref.watch(themesProvider);
    // For online we allow up to the same max; imposter count is chosen now but
    // re-validated against the real player count when the host starts.
    const maxAllowed = 4;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const BrandWordmark(fontSize: 18, letterSpacing: 2),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined,
                color: AppColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline,
                color: AppColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: themesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load themes:\n$e')),
        data: (themes) {
          _theme ??= themes.first;
          return GradientBackground(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // --- Hero ----------------------------------------------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const ImposterHero(size: 90, showSpeechBubble: false),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Create Room',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Theme dropdown ------------------------------------
                  Row(
                    children: const [
                      Icon(Icons.palette_outlined,
                          color: AppColors.cyan, size: 18),
                      SizedBox(width: 6),
                      SectionLabel('Theme'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _pickTheme(themes),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardFill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          _ThemeCircle(
                              themeId: _theme!.id,
                              icon: themeIcon(_theme!.id)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_theme!.name,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Imposters ----------------------------------------
                  Row(
                    children: const [
                      Icon(Icons.theater_comedy,
                          color: AppColors.primary, size: 18),
                      SizedBox(width: 6),
                      SectionLabel('Imposters', color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('You can adjust before starting.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _stepperButton(
                        Icons.remove,
                        _imposterCount > 1
                            ? () => setState(() => _imposterCount--)
                            : null,
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
                  ),
                  const SizedBox(height: 28),

                  // --- Create Room CTA ----------------------------------
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: lavenderButtonStyle(),
                      icon: _creating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check),
                      label: Text(_creating ? 'Creating…' : 'Create Room'),
                      onPressed: _creating ? null : _create,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline,
                            color: AppColors.cyan, size: 14),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Minimum $kMinPlayers players needed to start.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
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
            color: enabled ? AppColors.primary : AppColors.textTertiary,
            size: 24),
      ),
    ),
  );
}

class _ThemeCircle extends StatelessWidget {
  const _ThemeCircle({required this.themeId, required this.icon});
  final String themeId;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.themeTileColors(themeId);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: fg, size: 22),
    );
  }
}
