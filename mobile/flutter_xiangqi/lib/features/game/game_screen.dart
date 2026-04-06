import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/utils/board_visual_config.dart';
import '../../core/utils/captured_pieces_helper.dart';
import '../../data/models/game_state_model.dart';
import 'game_controller.dart';
import 'widgets/captured_pieces_panel.dart';
import 'widgets/move_history_strip.dart';
import 'widgets/side_to_move_banner.dart';
import 'widgets/xiangqi_board.dart';

/// Game screen: composes all game UI pieces.
class GameScreen extends ConsumerWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGame = ref.watch(gameControllerProvider(gameId));

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

class _GameBody extends ConsumerWidget {
  final GameStateModel game;
  final String gameId;

  const _GameBody({required this.game, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(gameUiProvider(gameId));
    final uiNotifier = ref.read(gameUiProvider(gameId).notifier);
    final isBoardInteractionLocked = uiState.isSubmitting || game.isAiThinking;
    final captured = CapturedPiecesHelper.fromHistory(game.moveHistory);

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Image.asset(
                'assets/images/bg/battle-bg-portrait.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: XiangqiColors.bgDark),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Color(0x00000000),
                    Color(0x88000000),
                    Color(0xEE000000),
                  ],
                  stops: [0.20, 0.65, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000),
                    Color(0x11000000),
                    Color(0x99000000),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.15),
                  radius: 1.0,
                  colors: [Color(0x664B2416), XiangqiColors.bgDark],
                  stops: [0.0, 0.9],
                ),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SideToMoveBanner(game: game),
            CapturedPiecesPanel(captured: captured),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const historyGap = 12.0;
                    const historyHeight = 56.0;
                    final widthFactor = constraints.maxWidth < 480
                        ? 0.96
                        : constraints.maxWidth < 900
                        ? 0.84
                        : 0.72;
                    final availableBoardHeight = math.max(
                      0.0,
                      constraints.maxHeight - historyHeight - historyGap,
                    );
                    final widthFromHeight =
                        availableBoardHeight *
                        BoardVisualConfig.wrapperAspectRatio;
                    final boardWidth = math.min(
                      math.min(constraints.maxWidth * widthFactor, 612.0),
                      widthFromHeight,
                    );

                    if (boardWidth <= 0) {
                      return const SizedBox.shrink();
                    }

                    return Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: boardWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AspectRatio(
                              aspectRatio: BoardVisualConfig.wrapperAspectRatio,
                              child: _BoardFrame(
                                child: IgnorePointer(
                                  ignoring: isBoardInteractionLocked,
                                  child: XiangqiBoard(
                                    game: game,
                                    uiState: uiState,
                                    onIntersectionTap: (row, col) {
                                      uiNotifier.tapIntersection(
                                        row,
                                        col,
                                        game,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: historyGap),
                            SizedBox(
                              height: historyHeight,
                              child: MoveHistoryStrip(
                                moveHistory: game.moveHistory,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BoardFrame extends StatelessWidget {
  final Widget child;

  const _BoardFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wrapperSize = Size(constraints.maxWidth, constraints.maxHeight);
        final scale = BoardVisualConfig.wrapperScale(wrapperSize);
        final cornerRadius = 6 * scale;
        final innerRuleInsets = BoardVisualConfig.innerRuleInsets(wrapperSize);
        final boardInsets = BoardVisualConfig.boardInsets(wrapperSize);
        final rodOverflow = BoardVisualConfig.rodOverflowPx * scale;
        final cornerInset = BoardVisualConfig.cornerInsetPx * scale;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            border: Border.all(
              color: const Color(0x80885A2A),
              width: math.max(0.9, scale),
            ),
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
                color: const Color(0x850A0502),
                blurRadius: 48 * scale,
                offset: Offset(0, 16 * scale),
              ),
              BoxShadow(
                color: const Color(0x4D0A0502),
                blurRadius: 14 * scale,
                offset: Offset(0, 4 * scale),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0x59FFF0C8),
                          Colors.transparent,
                          Colors.black.withAlpha(24),
                        ],
                        stops: const [0.0, 0.16, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: innerRuleInsets,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4 * scale),
                        border: Border.all(
                          color: XiangqiColors.boardFrame.withAlpha(72),
                          width: math.max(0.7, 0.9 * scale),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -rodOverflow,
                right: -rodOverflow,
                top: 0,
                child: _BoardRod(scale: scale),
              ),
              Positioned(
                left: -rodOverflow,
                right: -rodOverflow,
                bottom: 0,
                child: _BoardRod(scale: scale, isBottom: true),
              ),
              Positioned(
                top: cornerInset,
                left: cornerInset,
                child: _BoardCorner(scale: scale),
              ),
              Positioned(
                top: cornerInset,
                right: cornerInset,
                child: _BoardCorner(scale: scale),
              ),
              Positioned(
                bottom: cornerInset,
                left: cornerInset,
                child: _BoardCorner(scale: scale),
              ),
              Positioned(
                bottom: cornerInset,
                right: cornerInset,
                child: _BoardCorner(scale: scale),
              ),
              Padding(
                padding: boardInsets,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: XiangqiColors.boardFrameDark.withAlpha(38),
                      width: math.max(0.6, 0.8 * scale),
                    ),
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoardRod extends StatelessWidget {
  final bool isBottom;
  final double scale;

  const _BoardRod({required this.scale, this.isBottom = false});

  @override
  Widget build(BuildContext context) {
    final height = BoardVisualConfig.rodHeightPx * scale;
    final radius = Radius.circular(5 * scale);
    final knobOffset = BoardVisualConfig.rodKnobOffsetPx * scale;
    final knobTop = -3 * scale;

    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: isBottom
                      ? BorderRadius.vertical(bottom: radius)
                      : BorderRadius.vertical(top: radius),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: XiangqiColors.scrollRodColors,
                    stops: [0.0, 0.35, 0.65, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(102),
                      blurRadius: 8 * scale,
                      offset: Offset(0, 3 * scale),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: -knobOffset,
              top: knobTop,
              child: _BoardKnob(scale: scale),
            ),
            Positioned(
              right: -knobOffset,
              top: knobTop,
              child: _BoardKnob(scale: scale),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardKnob extends StatelessWidget {
  final double scale;

  const _BoardKnob({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: BoardVisualConfig.rodKnobSizePx * scale,
      height: BoardVisualConfig.rodKnobSizePx * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.24, -0.3),
          radius: 0.82,
          colors: [Color(0xFFD4A94A), Color(0xFF7E4E1A), Color(0xFFC09040)],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x66000000),
            blurRadius: 5 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
    );
  }
}

class _BoardCorner extends StatelessWidget {
  final double scale;

  const _BoardCorner({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Text(
      '\u25C8',
      style: TextStyle(
        color: const Color(0xFFA07838).withAlpha(115),
        fontSize: BoardVisualConfig.cornerFontSizePx * scale,
        height: 1,
      ),
    );
  }
}

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
