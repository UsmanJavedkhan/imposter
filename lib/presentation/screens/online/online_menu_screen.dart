import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/online_providers.dart';
import '../../widgets/gradient_background.dart';
import 'create_room_screen.dart';
import 'join_room_screen.dart';

/// Entry point for online play: pick a name, then create or join a room.
/// Also kicks off anonymous sign-in.
class OnlineMenuScreen extends ConsumerStatefulWidget {
  const OnlineMenuScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Online'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: auth.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not connect to the server:\n$e',
                    textAlign: TextAlign.center),
              ),
            ),
            data: (_) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18)),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create Room'),
                      onPressed: () =>
                          _go(CreateRoomScreen(playerName: _name)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18)),
                      icon: const Icon(Icons.login),
                      label: const Text('Join Room'),
                      onPressed: () => _go(JoinRoomScreen(playerName: _name)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
