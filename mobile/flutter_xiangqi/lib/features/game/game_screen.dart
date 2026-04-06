import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/utils/board_layout.dart';
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
              valueColor: AlwaysStoppedAnimation<Color>(
                XiangqiColors.goldLight,
              ),
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
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.1,
              colors: [Color(0xFF4B2416), XiangqiColors.bgDark],
              stops: [0.0, 0.78],
            ),
          ),
        ),

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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final widthFactor = constraints.maxWidth < 480
                        ? 0.96
                        : constraints.maxWidth < 900
                        ? 0.84
                        : 0.72;
                    final widthFromHeight =
                        constraints.maxHeight * BoardLayout.aspectRatio;
                    final boardWidth = math.min(
                      math.min(constraints.maxWidth * widthFactor, 540.0),
                      widthFromHeight,
                    );

                    return Center(
                      child: SizedBox(
                        width: boardWidth,
                        child: AspectRatio(
                          aspectRatio: BoardLayout.aspectRatio,
                          child: _BoardFrame(
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
                    );
                  },
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

class _BoardFrame extends StatelessWidget {
  final Widget child;

  const _BoardFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x80885A2A), width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            XiangqiColors.boardFrameFill,
            Color(0xFFE4D0AE),
            Color(0xFFD8C49A),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(132),
            blurRadius: 48,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(76),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: XiangqiColors.boardFrame.withAlpha(72),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(left: -10, right: -10, top: 0, child: _BoardRod()),
          const Positioned(
            left: -10,
            right: -10,
            bottom: 0,
            child: _BoardRod(isBottom: true),
          ),
          const Positioned(top: 11, left: 11, child: _BoardCorner()),
          const Positioned(top: 11, right: 11, child: _BoardCorner()),
          const Positioned(bottom: 11, left: 11, child: _BoardCorner()),
          const Positioned(bottom: 11, right: 11, child: _BoardCorner()),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: XiangqiColors.boardFrameDark.withAlpha(38),
                  width: 0.8,
                ),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardRod extends StatelessWidget {
  final bool isBottom;

  const _BoardRod({this.isBottom = false});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: 9,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: isBottom
                      ? const BorderRadius.vertical(bottom: Radius.circular(5))
                      : const BorderRadius.vertical(top: Radius.circular(5)),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: XiangqiColors.scrollRodColors,
                    stops: [0.0, 0.35, 0.65, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(102),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(left: -4, top: -3, child: _BoardKnob()),
            const Positioned(right: -4, top: -3, child: _BoardKnob()),
          ],
        ),
      ),
    );
  }
}

class _BoardKnob extends StatelessWidget {
  const _BoardKnob();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.24, -0.3),
          radius: 0.82,
          colors: [Color(0xFFD4A94A), Color(0xFF7E4E1A), Color(0xFFC09040)],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _BoardCorner extends StatelessWidget {
  const _BoardCorner();

  @override
  Widget build(BuildContext context) {
    return Text(
      '\u25C8',
      style: TextStyle(
        color: XiangqiColors.boardFrameDark.withAlpha(110),
        fontSize: 9,
        height: 1,
      ),
    );
  }
}

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
