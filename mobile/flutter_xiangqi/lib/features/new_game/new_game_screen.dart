import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'new_game_controller.dart';

class NewGameScreen extends ConsumerWidget {
  const NewGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newGameControllerProvider);
    final controller = ref.read(newGameControllerProvider.notifier);

    ref.listen(newGameControllerProvider.select((s) => s.creationState), (
      previous,
      next,
    ) {
      next.when(
        data: (game) {
          if (game?.gameId != null) {
            context.go('/game/${game!.gameId}');
          }
        },
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create game: $error')),
          );
        },
        loading: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Game'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select Difficulty:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'easy', label: Text('Easy')),
                ButtonSegment(value: 'normal', label: Text('Normal')),
                ButtonSegment(value: 'hard', label: Text('Hard')),
              ],
              selected: {state.difficulty},
              onSelectionChanged: (Set<String> newSelection) {
                controller.setDifficulty(newSelection.first);
              },
            ),
            const SizedBox(height: 24),
            const Text('Select Player Side:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'r', label: Text('Red (First)')),
                ButtonSegment(value: 'b', label: Text('Black')),
              ],
              selected: {state.playerSide},
              onSelectionChanged: (Set<String> newSelection) {
                controller.setPlayerSide(newSelection.first);
              },
            ),
            const Spacer(),
            if (state.creationState.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: () {
                  controller.createGame();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Start Game', style: TextStyle(fontSize: 18)),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
