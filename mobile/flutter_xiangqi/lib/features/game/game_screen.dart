import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_state_model.dart';
import 'game_controller.dart';
import 'widgets/side_to_move_banner.dart';
import 'widgets/xiangqi_board.dart';

/// Game screen: composes [SideToMoveBanner] + [XiangqiBoard].
///
/// Responsibilities:
///   • Watch the game state provider and the UI state provider.
///   • Forward board taps to [GameUiNotifier.tapIntersection].
///   • Show a loading overlay during move submission.
///   • Show a SnackBar when a move is rejected or a network error occurs.
///   • Hand display data down to child widgets.
///
/// Does NOT contain board rendering or game-rule logic.
class GameScreen extends ConsumerWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGame = ref.watch(gameControllerProvider(gameId));

    // Show SnackBar whenever a move error appears.
    ref.listen(gameUiProvider(gameId), (prev, next) {
      if (next.moveError != null && next.moveError != prev?.moveError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.moveError!),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xiangqi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(gameControllerProvider(gameId).notifier).refreshGame(),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncGame.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorBody(
            error: error,
            onRetry: () =>
                ref.read(gameControllerProvider(gameId).notifier).refreshGame(),
          ),
          data: (game) => _GameBody(
            game: game,
            gameId: gameId,
          ),
        ),
      ),
    );
  }
}

// ── Game body (when data is loaded) ─────────────────────────────────────────

class _GameBody extends ConsumerWidget {
  final GameStateModel game;
  final String gameId;

  const _GameBody({required this.game, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(gameUiProvider(gameId));
    final uiNotifier = ref.read(gameUiProvider(gameId).notifier);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status banner ──────────────────────────────────────────────
            SideToMoveBanner(game: game),

            // ── Board ─────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 9 / 10,
                    child: XiangqiBoard(
                      game: game,
                      uiState: uiState,
                      onIntersectionTap: (row, col) {
                        uiNotifier.tapIntersection(row, col, game);
                      },
                    ),
                  ),
                ),
              ),
            ),

            // ── Debug footer ───────────────────────────────────────────────
            const Divider(height: 1),
            _DebugFooter(game: game, uiState: uiState),
          ],
        ),

        // ── Move-submission loading overlay ────────────────────────────────
        if (uiState.isSubmitting)
          const _SubmittingOverlay(),
      ],
    );
  }
}

// ── Submitting overlay ────────────────────────────────────────────────────────

class _SubmittingOverlay extends StatelessWidget {
  const _SubmittingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withAlpha(60),
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 14),
                  Text('Sending move…'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

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
class _DebugFooter extends StatelessWidget {
  final GameStateModel game;
  final dynamic uiState;

  const _DebugFooter({required this.game, required this.uiState});

  @override
  Widget build(BuildContext context) {
    final pieceCount = game.boardState
        .expand<dynamic>((row) => row)
        .where((p) => !p.isEmpty)
        .length;

    final selInfo = (uiState.hasSelection)
        ? 'Sel: (${uiState.selectedRow},${uiState.selectedCol})'
        : 'Sel: —';

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
        '$selInfo · '
        'Status: ${game.status}',
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
