import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/online_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/ui_kit.dart';
import 'create_room_screen.dart';
import 'join_room_screen.dart';

/// Entry point for online play: pick a name, then create or join a room.
/// Also kicks off anonymous sign-in.
///
/// When [pendingJoinCode] is supplied (because the user tapped an invite
/// link / deep-link) the menu collapses to a single "Join Room ABC123 as
/// [name]" CTA — they don't need to see Create Room.
class OnlineMenuScreen extends ConsumerStatefulWidget {
  const OnlineMenuScreen({super.key, this.pendingJoinCode});

  final String? pendingJoinCode;

  @override
  ConsumerState<OnlineMenuScreen> createState() => _OnlineMenuScreenState();
}

class _OnlineMenuScreenState extends ConsumerState<OnlineMenuScreen> {
  final _nameController = TextEditingController(text: 'Player');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _name => _nameController.text.trim();

  void _go(Widget screen) {
    if (_name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your name first.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    // Ensures we are signed in anonymously before playing online.
    final auth = ref.watch(authUidProvider);
    final pendingCode = widget.pendingJoinCode;

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
          child: auth.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not connect to the server:\n$e',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: AppColors.textPrimary)),
              ),
            ),
            data: (_) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                    pendingCode != null
                        ? 'Join Room'
                        : 'Play Online',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  pendingCode != null
                      ? "You've been invited to room $pendingCode"
                      : 'Play with friends on other devices',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: const [
                    Icon(Icons.person_outline,
                        color: AppColors.cyan, size: 18),
                    SizedBox(width: 6),
                    SectionLabel('Your Name'),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 24),

                // Deep-link flow → single Join button; standard flow → both
                // Create + Join cards.
                if (pendingCode != null) ...[
                  MenuCard(
                    icon: Icons.login,
                    title: 'Join Room $pendingCode',
                    subtitle: 'Tap to enter the room',
                    accent: AppColors.primary,
                    filled: true,
                    showArrow: true,
                    onTap: () => _go(JoinRoomScreen(
                      playerName: _name,
                      initialCode: pendingCode,
                      autoJoin: true,
                    )),
                  ),
                ] else ...[
                  MenuCard(
                    icon: Icons.add_circle_outline,
                    title: 'Create Room',
                    subtitle: 'Host a new game',
                    accent: AppColors.primary,
                    filled: true,
                    showArrow: true,
                    onTap: () => _go(CreateRoomScreen(playerName: _name)),
                  ),
                  const SizedBox(height: 12),
                  MenuCard(
                    icon: Icons.login,
                    title: 'Join Room',
                    subtitle: 'Enter a 6-character code',
                    accent: AppColors.cyan,
                    showArrow: true,
                    onTap: () => _go(JoinRoomScreen(playerName: _name)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
