import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_state_model.dart';
import 'game_controller.dart';
import 'widgets/side_to_move_banner.dart';
import 'widgets/xiangqi_board.dart';

/// Game screen: composes [SideToMoveBanner] + [XiangqiBoard].
///
/// Responsibilities:
///   • Watch the game state provider.
///   • Hand the data down to child widgets.
///   • Show loading / error states.
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
      body: SafeArea(
        child: asyncGame.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorBody(
            error: error,
            onRetry: controller.refreshGame,
          ),
          data: (game) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Status banner ────────────────────────────────────────────────
              SideToMoveBanner(game: game),

              // ── Board ─────────────────────────────────────────────────────
              // Expanded fills remaining vertical space; AspectRatio then
              // scales the board so it is never taller than that space while
              // keeping the correct Xiangqi proportions.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Center(
                    child: AspectRatio(
                      // Limit the board's own max height to leave room for
                      // the debug footer without adding a scroll view.
                      aspectRatio: 9 / 10, // matches BoardLayout.aspectRatio
                      child: XiangqiBoard(game: game),
                    ),
                  ),
                ),
              ),

              // ── Debug footer (remove after Phase 5) ────────────────────
              const Divider(height: 1),
              _DebugFooter(game: game),
            ],
          ),
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

/// One-line debug footer — key facts visible at a glance.
/// Remove after Phase 5 (move submission) is validated.
class _DebugFooter extends StatelessWidget {
  final GameStateModel game;

  const _DebugFooter({required this.game});

  @override
  Widget build(BuildContext context) {
    final pieceCount = game.boardState
        .expand<dynamic>((row) => row)
        .where((p) => !p.isEmpty)
        .length;

    final style = Theme.of(context)
        .textTheme
        .labelSmall!
        .copyWith(color: Colors.grey.shade600);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        'ID: ${game.gameId ?? '—'} · '
        'Turn: ${game.currentTurn} · '
        'Pieces: $pieceCount · '
        'Status: ${game.status}',
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
