import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/utils/board_layout.dart';
import '../../../data/models/game_state_model.dart';
import '../../../data/models/move_model.dart';
import '../../../data/models/piece_model.dart';
import '../state/game_ui_state.dart';
import 'board_background_painter.dart';
import 'last_move_overlay.dart';
import 'legal_moves_overlay.dart';
import 'piece_widget.dart';

/// Renders the complete Xiangqi board: background + overlays + all pieces.
///
/// The latest move is animated as a short glide from source to target so
/// pieces do not visually teleport when a new board state arrives.
class XiangqiBoard extends StatefulWidget {
  final GameStateModel game;

  /// UI state for selection highlight and legal-moves overlay.
  final GameUiState? uiState;

  /// Called when the user taps any board intersection (row 0-9, col 0-8).
  final void Function(int row, int col)? onIntersectionTap;

  const XiangqiBoard({
    super.key,
    required this.game,
    this.uiState,
    this.onIntersectionTap,
  });

  @override
  State<XiangqiBoard> createState() => _XiangqiBoardState();
}

class _XiangqiBoardState extends State<XiangqiBoard>
    with SingleTickerProviderStateMixin {
  static const Duration _moveAnimationDuration = Duration(milliseconds: 280);

  late final AnimationController _moveController;
  late final Animation<double> _moveAnimation;

  _AnimatedMove? _animatedMove;
  String? _lastMoveSignature;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: _moveAnimationDuration,
    );
    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOutCubic,
    );
    _moveController.addStatusListener(_handleAnimationStatus);
    _lastMoveSignature = _moveSignature(widget.game.lastMove);
  }

  @override
  void didUpdateWidget(covariant XiangqiBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeAnimateLatestMove(oldWidget.game, widget.game);
  }

  @override
  void dispose() {
    _moveController.removeStatusListener(_handleAnimationStatus);
    _moveController.dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() {
      _animatedMove = null;
    });
  }

  void _maybeAnimateLatestMove(
    GameStateModel previousGame,
    GameStateModel nextGame,
  ) {
    final signature = _moveSignature(nextGame.lastMove);
    if (signature == null) {
      _lastMoveSignature = null;
      _moveController.stop();
      if (_animatedMove != null) {
        setState(() {
          _animatedMove = null;
        });
      }
      return;
    }

    if (signature == _lastMoveSignature) {
      return;
    }

    if (nextGame.moveHistory.length < previousGame.moveHistory.length) {
      _lastMoveSignature = signature;
      _moveController.stop();
      if (_animatedMove != null) {
        setState(() {
          _animatedMove = null;
        });
      }
      return;
    }

    final move = nextGame.lastMove;
    final pieceCode = _resolveAnimatedPieceCode(nextGame, move);
    if (move == null || pieceCode == null || pieceCode.isEmpty) {
      _lastMoveSignature = signature;
      return;
    }

    _lastMoveSignature = signature;
    setState(() {
      _animatedMove = _AnimatedMove(
        fromRow: move.from[0],
        fromCol: move.from[1],
        toRow: move.to[0],
        toCol: move.to[1],
        piece: PieceModel(code: pieceCode),
      );
    });
    _moveController.forward(from: 0);
  }

  String? _resolveAnimatedPieceCode(GameStateModel game, MoveModel? move) {
    if (move == null || move.from.length < 2 || move.to.length < 2) {
      return null;
    }
    if (move.piece != null && move.piece!.isNotEmpty) {
      return move.piece;
    }

    final toRow = move.to[0];
    final toCol = move.to[1];
    final pieceCode = game.boardState[toRow][toCol].code;
    return pieceCode.isEmpty ? null : pieceCode;
  }

  String? _moveSignature(MoveModel? move) {
    if (move == null || move.from.length < 2 || move.to.length < 2) {
      return null;
    }
    return '${move.piece ?? ''}:${move.from[0]},${move.from[1]}'
        '->${move.to[0]},${move.to[1]}:${move.captured ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardW = constraints.maxWidth;
        final boardH = constraints.maxHeight;

        Widget board = AnimatedBuilder(
          animation: _moveAnimation,
          builder: (context, _) {
            final animatedMove = _animatedMove;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                const BoardBackground(),
                LastMoveOverlay(
                  lastMove: widget.game.lastMove,
                  boardW: boardW,
                  boardH: boardH,
                  showSourceMarker: true,
                  showTargetRing: false,
                ),
                LegalMovesOverlay(
                  legalMoves: widget.uiState?.legalMovesForSelected,
                  boardW: boardW,
                  boardH: boardH,
                ),
                ..._buildPieces(
                  boardW,
                  boardH,
                  hiddenDestination: animatedMove,
                ),
                LastMoveOverlay(
                  lastMove: widget.game.lastMove,
                  boardW: boardW,
                  boardH: boardH,
                  showSourceMarker: false,
                  showTargetRing: animatedMove == null,
                ),
                if (animatedMove != null)
                  _buildAnimatedPiece(animatedMove, boardW, boardH),
              ],
            );
          },
        );

        if (widget.onIntersectionTap != null) {
          board = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final local = details.localPosition;
              final rc = _positionToRowCol(local.dx, local.dy, boardW, boardH);
              if (rc != null) {
                widget.onIntersectionTap!(rc.$1, rc.$2);
              }
            },
            child: board,
          );
        }

        return board;
      },
    );
  }

  List<Widget> _buildPieces(
    double boardW,
    double boardH, {
    _AnimatedMove? hiddenDestination,
  }) {
    final pieces = <Widget>[];
    final selectedPieces = <Widget>[];
    final size = BoardLayout.pieceSize(boardW, boardH);
    final half = size / 2;
    final captureTargets = _captureTargets();

    for (int row = 0; row < widget.game.boardState.length; row++) {
      final rowList = widget.game.boardState[row];
      for (int col = 0; col < rowList.length; col++) {
        final piece = rowList[col];
        if (piece.isEmpty) continue;
        if (_isHiddenAnimatedDestination(piece, row, col, hiddenDestination)) {
          continue;
        }

        final pieceWidget = _positionedPiece(
          piece,
          row,
          col,
          boardW,
          boardH,
          size,
          half,
          isCaptureTarget: captureTargets.contains('$row,$col'),
          isInCheck:
              piece.type?.toUpperCase() == 'K' &&
              widget.game.inCheck == piece.color,
        );

        final isSelected =
            widget.uiState != null &&
            widget.uiState!.selectedRow == row &&
            widget.uiState!.selectedCol == col;

        (isSelected ? selectedPieces : pieces).add(pieceWidget);
      }
    }

    return [...pieces, ...selectedPieces];
  }

  bool _isHiddenAnimatedDestination(
    PieceModel piece,
    int row,
    int col,
    _AnimatedMove? hiddenDestination,
  ) {
    if (hiddenDestination == null) return false;
    return row == hiddenDestination.toRow &&
        col == hiddenDestination.toCol &&
        piece.code == hiddenDestination.piece.code;
  }

  Widget _positionedPiece(
    PieceModel piece,
    int row,
    int col,
    double boardW,
    double boardH,
    double size,
    double half, {
    required bool isCaptureTarget,
    required bool isInCheck,
  }) {
    final isSelected =
        widget.uiState != null &&
        widget.uiState!.selectedRow == row &&
        widget.uiState!.selectedCol == col;

    final x = BoardLayout.intersectionX(col, boardW) - half;
    final y = BoardLayout.intersectionY(row, boardH) - half;

    Widget pieceWidget = PieceWidget(
      color: piece.color!,
      type: piece.type!,
      size: size,
      isSelected: isSelected,
      isCaptureTarget: isCaptureTarget,
      isInCheck: isInCheck,
    );

    if (widget.onIntersectionTap != null) {
      pieceWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onIntersectionTap!(row, col),
        child: pieceWidget,
      );
    }

    return Positioned(
      key: ValueKey('piece-${piece.code}-$row-$col'),
      left: x,
      top: y,
      child: pieceWidget,
    );
  }

  Widget _buildAnimatedPiece(_AnimatedMove move, double boardW, double boardH) {
    final size = BoardLayout.pieceSize(boardW, boardH);
    final half = size / 2;
    final startX = BoardLayout.intersectionX(move.fromCol, boardW) - half;
    final endX = BoardLayout.intersectionX(move.toCol, boardW) - half;
    final startY = BoardLayout.intersectionY(move.fromRow, boardH) - half;
    final endY = BoardLayout.intersectionY(move.toRow, boardH) - half;
    final progress = _moveAnimation.value;
    final left = lerpDouble(startX, endX, progress) ?? endX;
    final top = lerpDouble(startY, endY, progress) ?? endY;
    final isInCheck =
        move.piece.type?.toUpperCase() == 'K' &&
        widget.game.inCheck == move.piece.color;

    return Positioned(
      key: ValueKey(
        'animated-${move.piece.code}-${move.fromRow}-${move.fromCol}-${move.toRow}-${move.toCol}',
      ),
      left: left,
      top: top,
      child: IgnorePointer(
        child: PieceWidget(
          color: move.piece.color!,
          type: move.piece.type!,
          size: size,
          isSelected: false,
          isCaptureTarget: false,
          isInCheck: isInCheck,
        ),
      ),
    );
  }

  Set<String> _captureTargets() {
    final moves = widget.uiState?.legalMovesForSelected;
    if (moves == null || moves.isEmpty) return const <String>{};

    final targets = <String>{};
    for (final move in moves) {
      if (move.length < 2) continue;
      final row = move[0];
      final col = move[1];
      final piece = widget.game.boardState[row][col];
      if (!piece.isEmpty && piece.color != widget.game.currentTurn) {
        targets.add('$row,$col');
      }
    }
    return targets;
  }

  /// Converts a pixel tap position to the nearest board (row, col).
  /// Returns null if outside the grid.
  (int, int)? _positionToRowCol(
    double px,
    double py,
    double boardW,
    double boardH,
  ) {
    final cellW = BoardLayout.cellWidth(boardW);
    final cellH = BoardLayout.cellHeight(boardH);

    final col = ((px / cellW) - BoardLayout.outerPaddingCells).round();
    final row = ((py / cellH) - BoardLayout.outerPaddingCells).round();

    if (row < 0 || row >= BoardLayout.ranks) return null;
    if (col < 0 || col >= BoardLayout.files) return null;
    return (row, col);
  }
}

class _AnimatedMove {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final PieceModel piece;

  const _AnimatedMove({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.piece,
  });
}
