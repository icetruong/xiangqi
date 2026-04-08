import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/utils/board_visual_config.dart';
import '../../core/utils/captured_pieces_helper.dart';
import '../../data/models/game_state_model.dart';
import '../../data/providers.dart';
import 'game_controller.dart';
import 'models/game_action_type.dart';
import 'models/game_result_view_model.dart';
import 'widgets/captured_pieces_panel.dart';
import 'widgets/game_action_panel.dart';
import 'widgets/game_result_modal.dart';
import 'widgets/game_top_header.dart';
import 'widgets/move_history_strip.dart';
import 'widgets/versus_header.dart';
import 'widgets/xiangqi_board.dart';
import '../../shared/widgets/themed_confirm_dialog.dart';

/// Game screen: composes all game UI pieces.
class GameScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  String? _lastPresentedResultSignature;
  bool _resultPresentationQueued = false;
  bool _isPresentingResult = false;

  @override
  Widget build(BuildContext context) {
    final asyncGame = ref.watch(gameControllerProvider(widget.gameId));

    ref.listen(gameUiProvider(widget.gameId), (prev, next) {
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

    _queueResultPresentation(asyncGame.asData?.value);

    return Scaffold(
      backgroundColor: XiangqiColors.darkBrown,
      appBar: GameTopHeader(
        onBack: () {
          if (GoRouter.of(context).canPop()) {
            context.pop();
            return;
          }
          context.go('/');
        },
        onRefresh: () => ref
            .read(gameControllerProvider(widget.gameId).notifier)
            .refreshGame(),
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
            onRetry: () => ref
                .read(gameControllerProvider(widget.gameId).notifier)
                .refreshGame(),
          ),
          data: (game) => _GameBody(game: game, gameId: widget.gameId),
        ),
      ),
    );
  }

  void _queueResultPresentation(GameStateModel? game) {
    if (game == null) {
      return;
    }

    if (game.status != 'finished') {
      _lastPresentedResultSignature = null;
      return;
    }

    final signature = _resultSignature(game);
    if (_lastPresentedResultSignature == signature ||
        _resultPresentationQueued ||
        _isPresentingResult) {
      return;
    }

    _lastPresentedResultSignature = signature;
    _resultPresentationQueued = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resultPresentationQueued = false;
      if (!mounted) {
        return;
      }
      _presentResult(game);
    });
  }

  Future<void> _presentResult(GameStateModel game) async {
    if (_isPresentingResult) {
      return;
    }

    _isPresentingResult = true;
    try {
      final result = await GameResultModal.show(
        context,
        viewModel: GameResultViewModel.fromGame(game),
        onPlayAgain: () => _createReplayGame(game),
      );

      if (!mounted || result == null) {
        return;
      }

      switch (result.action) {
        case GameResultModalAction.stay:
          return;
        case GameResultModalAction.goHome:
          context.go('/');
          return;
        case GameResultModalAction.playAgain:
          final nextGameId = result.nextGameId;
          if (nextGameId != null && nextGameId.isNotEmpty) {
            context.go('/game/$nextGameId');
          }
          return;
      }
    } finally {
      _isPresentingResult = false;
    }
  }

  Future<String> _createReplayGame(GameStateModel game) async {
    final difficulty = (game.difficulty?.isNotEmpty ?? false)
        ? game.difficulty!
        : 'normal';
    final playerSide = game.playerSide == 'b' || game.playerSide == 'r'
        ? game.playerSide!
        : 'r';

    final nextGame = await ref
        .read(gameRepositoryProvider)
        .createGame(difficulty, playerSide);
    final gameId = nextGame.gameId;
    if (gameId == null || gameId.isEmpty) {
      throw StateError('Replay game id is missing.');
    }
    return gameId;
  }

  String _resultSignature(GameStateModel game) {
    return [
      game.gameId ?? widget.gameId,
      game.status,
      game.winner ?? '-',
      game.endReason ?? '-',
      '${game.moveHistory.length}',
    ].join('|');
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
    final isBoardInteractionLocked =
        uiState.isSubmitting || uiState.isPerformingAction || game.isAiThinking;
    final captured = CapturedPiecesHelper.fromHistory(game.moveHistory);

    Future<void> handleAction(GameActionType action) async {
      final confirmed = await ThemedConfirmDialog.show(context, action: action);
      if (!confirmed || !context.mounted) {
        return;
      }

      if (action == GameActionType.exit) {
        context.go('/');
        return;
      }

      if (!context.mounted) {
        return;
      }

      await uiNotifier.submitGameAction(action, game);
    }

    double contentWidthFactor(double maxWidth) {
      if (maxWidth < 480) {
        return 0.98;
      }
      if (maxWidth < 900) {
        return 0.84;
      }
      return 0.72;
    }

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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const versusGap = 8.0;
              const versusHeight = VersusHeader.compactHeight;
              const historyGap = 10.0;
              const historyHeight = 56.0;
              const actionGap = 6.0;
              final widthFactor = contentWidthFactor(constraints.maxWidth);
              final maxBoardWidth = math.min(
                constraints.maxWidth * widthFactor,
                612.0,
              );
              final minComfortBoardWidth = math.min(maxBoardWidth, 260.0);
              final heightBudgetWidth =
                  math.max(
                    0.0,
                    constraints.maxHeight -
                        versusHeight -
                        versusGap -
                        historyHeight -
                        historyGap -
                        GameActionPanel.compactHeight -
                        actionGap,
                  ) *
                  BoardVisualConfig.wrapperAspectRatio;
              final boardWidth = math.min(
                maxBoardWidth,
                math.max(heightBudgetWidth, minComfortBoardWidth),
              );

              if (boardWidth <= 0) {
                return const SizedBox.shrink();
              }

              return ScrollConfiguration(
                behavior: const _GameScreenScrollBehavior(),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: boardWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AspectRatio(
                                  aspectRatio:
                                      BoardVisualConfig.wrapperAspectRatio,
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
                                const SizedBox(height: versusGap),
                                SizedBox(
                                  height: versusHeight,
                                  child: VersusHeader(game: game),
                                ),
                                const SizedBox(height: historyGap),
                                SizedBox(
                                  height: historyHeight,
                                  child: MoveHistoryStrip(
                                    moveHistory: game.moveHistory,
                                  ),
                                ),
                                const SizedBox(height: actionGap),
                                GameActionPanel(
                                  isGameFinished: game.status != 'ongoing',
                                  isBusy:
                                      uiState.isSubmitting ||
                                      uiState.isPerformingAction,
                                  activeAction: uiState.activeAction,
                                  onResign: () =>
                                      handleAction(GameActionType.resign),
                                  onDraw: () =>
                                      handleAction(GameActionType.draw),
                                  onExit: () =>
                                      handleAction(GameActionType.exit),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!captured.isEmpty) ...[
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: boardWidth,
                              child: CapturedPiecesPanel(captured: captured),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
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

class _GameScreenScrollBehavior extends ScrollBehavior {
  const _GameScreenScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
