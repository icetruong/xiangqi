import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_controller.dart';
import 'widgets/side_to_move_banner.dart';
import 'widgets/xiangqi_board.dart';

/// Game screen: composes [SideToMoveBanner] + [XiangqiBoard].
///
/// Responsibilities:
///   • Watch the game state provider.
///   • Hand the data down to child widgets.
///   • Show loading / error states.
///   • Provide a compact debug summary while board UI is being validated.
///
/// Does NOT contain board rendering or game-rule logic.
class GameScreen extends ConsumerWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGame = ref.watch(gameControllerProvider(gameId));
    final controller = ref.read(gameControllerProvider(gameId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xiangqi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: controller.refreshGame,
          ),
        ],
      ),
      body: asyncGame.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(
          error: error,
          onRetry: controller.refreshGame,
        ),
        data: (game) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status banner ──────────────────────────────────────────
            SideToMoveBanner(game: game),

            // ── Board ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: XiangqiBoard(game: game),
            ),

            // ── Debug summary (keep until Phase 5 is done) ─────────────
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: _DebugSummary(game: game),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ─────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorBody({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Failed to load game',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '$error',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact raw data dump useful for verifying backend connectivity.
/// Remove or collapse this panel once Phase 5 (move submission) is done.
class _DebugSummary extends StatelessWidget {
  final dynamic game;

  const _DebugSummary({required this.game});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context)
        .textTheme
        .bodySmall!
        .copyWith(color: Colors.grey.shade700);

    final pieceCount = game.boardState
        .expand((row) => row)
        .where((p) => !p.isEmpty)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('── Debug info ──', style: textStyle.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Game ID : ${game.gameId ?? '—'}', style: textStyle),
        Text('Difficulty : ${game.difficulty ?? '—'}', style: textStyle),
        Text('Player side : ${game.playerSide ?? '—'}', style: textStyle),
        Text('Side to move : ${game.currentTurn}', style: textStyle),
        Text('AI thinking : ${game.isAiThinking}', style: textStyle),
        Text('Winner : ${game.winner ?? '—'}', style: textStyle),
        Text('Pieces on board : $pieceCount', style: textStyle),
        Text('Move history : ${game.moveHistory.length}', style: textStyle),
      ],
    );
  }
}
