import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_controller.dart';

class GameScreen extends ConsumerWidget {
  final String gameId;

  const GameScreen({
    super.key,
    required this.gameId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider(gameId));
    final controller = ref.read(gameControllerProvider(gameId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playing Xiangqi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshGame(),
          ),
        ],
      ),
      body: gameState.when(
        data: (game) {
          final pieceCount = game.boardState
              .expand((row) => row)
              .where((piece) => !piece.isEmpty)
              .length;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Game ID: ${game.gameId ?? gameId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${game.status}'),
                  const SizedBox(height: 8),
                  Text('Player Side: ${game.playerSide}'),
                  const SizedBox(height: 8),
                  Text('Side to Move: ${game.currentTurn}'),
                  const SizedBox(height: 8),
                  Text('Difficulty: ${game.difficulty}'),
                  const SizedBox(height: 8),
                  Text('Is AI Thinking: ${game.isAiThinking}'),
                  const SizedBox(height: 8),
                  Text('Result: ${game.winner ?? "N/A"}'),
                  const SizedBox(height: 8),
                  Text('Number of pieces: $pieceCount'),
                  const SizedBox(height: 8),
                  Text('Move history count: ${game.moveHistory.length}'),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.refreshGame(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
