import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/utils/captured_pieces_helper.dart';
import '../../data/models/game_state_model.dart';
import 'game_controller.dart';
import 'widgets/ai_thinking_indicator.dart';
import 'widgets/captured_pieces_panel.dart';
import 'widgets/move_history_panel.dart';
import 'widgets/side_to_move_banner.dart';
import 'widgets/xiangqi_board.dart';

/// Game screen: composes all game UI pieces.
///
/// Responsibilities:
///   • Watch the game state provider and the UI state provider.
///   • Forward board taps to [GameUiNotifier.tapIntersection].
///   • Show a loading overlay during move submission.
///   • Show a SnackBar when a move is rejected or a network error occurs.
///   • Hand display data down to child widgets (keeps this class thin).
///
/// Does NOT contain board rendering, game-rule logic, or overlay painting.
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
      backgroundColor: XiangqiColors.darkBrown,
      appBar: AppBar(
        backgroundColor: XiangqiColors.darkBrown,
        foregroundColor: XiangqiColors.goldLight,
        title: const Text(
          'XIANGQI',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            color: XiangqiColors.goldLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: XiangqiColors.goldLight),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(gameControllerProvider(gameId).notifier).refreshGame(),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncGame.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(XiangqiColors.goldLight),
            ),
          ),
          error: (error, _) => _ErrorBody(
            error: error,
            onRetry: () =>
                ref.read(gameControllerProvider(gameId).notifier).refreshGame(),
          ),
          data: (game) => _GameBody(game: game, gameId: gameId),
        ),
      ),
    );
  }
}

// ── Game body ────────────────────────────────────────────────────────────────

class _GameBody extends ConsumerWidget {
  final GameStateModel game;
  final String gameId;

  const _GameBody({required this.game, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(gameUiProvider(gameId));
    final uiNotifier = ref.read(gameUiProvider(gameId).notifier);

    final captured = CapturedPiecesHelper.fromHistory(game.moveHistory);

    return Stack(
      children: [
        // ── Dark background behind the board area ──────────────────────────
        Container(color: XiangqiColors.darkBrown),

        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status banner ────────────────────────────────────────────────
            SideToMoveBanner(game: game),

            // ── AI thinking slim indicator ───────────────────────────────────
            AiThinkingIndicator(visible: game.isAiThinking),

            // ── Captured pieces ──────────────────────────────────────────────
            CapturedPiecesPanel(captured: captured),

            // ── Board ─────────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 9 / 10,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: XiangqiColors.gold.withAlpha(160),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(120),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
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
            ),

            // ── Move history panel (collapsible) ─────────────────────────────
            MoveHistoryPanel(moveHistory: game.moveHistory),
          ],
        ),

        // ── Blocking overlays ────────────────────────────────────────────────
        if (uiState.isSubmitting)
          const AbsorbPointer(child: _SubmittingOverlay())
        else if (game.isAiThinking)
          const AbsorbPointer(child: _AiThinkingOverlay()),
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
        color: Colors.black.withAlpha(100),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: XiangqiColors.parchment,
              border: Border.all(color: XiangqiColors.gold, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x88000000), blurRadius: 20),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      XiangqiColors.crimson,
                    ),
                  ),
                ),
                SizedBox(width: 14),
                Text(
                  'Sending move…',
                  style: TextStyle(
                    color: XiangqiColors.darkBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── AI Thinking overlay ───────────────────────────────────────────────────────

class _AiThinkingOverlay extends StatelessWidget {
  const _AiThinkingOverlay();

  @override
  Widget build(BuildContext context) {
    // Transparent overlay: absorbs pointer events but does NOT dim the board.
    // The slim [AiThinkingIndicator] banner above the board is the visual cue.
    return const Positioned.fill(child: SizedBox.shrink());
  }
}

// ── Error body ────────────────────────────────────────────────────────────────

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
