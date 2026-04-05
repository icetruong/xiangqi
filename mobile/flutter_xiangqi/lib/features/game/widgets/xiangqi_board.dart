import 'package:flutter/material.dart';
import '../../../core/utils/board_layout.dart';
import '../../../data/models/game_state_model.dart';
import '../../../data/models/piece_model.dart';
import '../state/game_ui_state.dart';
import 'board_background_painter.dart';
import 'last_move_overlay.dart';
import 'legal_moves_overlay.dart';
import 'piece_widget.dart';

/// Renders the complete Xiangqi board: background + overlays + all pieces.
///
/// Stack layers (bottom to top):
///   1. [BoardBackground] — warm-wood background with grid lines
///   2. [LastMoveOverlay] — amber rings on from/to squares of the last move
///   3. [LegalMovesOverlay] — green dots on valid destinations for selected piece
///   4. Piece [Positioned] widgets — pieces with selection ring inside [PieceWidget]
///
/// Layout strategy:
///   • Parent constrains via [AspectRatio] + [Expanded]; we always get finite bounds.
///   • [LayoutBuilder] exposes pixel size for coordinate math.
///   • Board dimensions are forwarded to overlays so they share [BoardLayout] math.
///
/// Interaction:
///   • Full-board [GestureDetector] catches taps on empty intersections.
///   • Each piece also fires [onIntersectionTap] individually for faster response.
class XiangqiBoard extends StatelessWidget {
  final GameStateModel game;

  /// UI state for selection highlight / legal-moves overlay.
  final GameUiState? uiState;

  /// Called when the user taps any board intersection (row 0–9, col 0–8).
  final void Function(int row, int col)? onIntersectionTap;

  const XiangqiBoard({
    super.key,
    required this.game,
    this.uiState,
    this.onIntersectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardW = constraints.maxWidth;
        final boardH = constraints.maxHeight;

        Widget board = Stack(
          children: [
            // Layer 1: board background
            const BoardBackground(),

            // Layer 2: last-move amber rings
            LastMoveOverlay(
              lastMove: game.lastMove,
              boardW: boardW,
              boardH: boardH,
            ),

            // Layer 3: legal-move destination dots (only when a piece is selected)
            LegalMovesOverlay(
              legalMoves: uiState?.legalMovesForSelected,
              boardW: boardW,
              boardH: boardH,
            ),

            // Layer 4: pieces (selection ring rendered inside PieceWidget)
            ..._buildPieces(boardW, boardH),
          ],
        );

        // Full-board gesture detector for empty-intersection taps.
        if (onIntersectionTap != null) {
          board = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final local = details.localPosition;
              final rc = _positionToRowCol(local.dx, local.dy, boardW, boardH);
              if (rc != null) {
                onIntersectionTap!(rc.$1, rc.$2);
              }
            },
            child: board,
          );
        }

        return board;
      },
    );
  }

  // ── Piece placement ────────────────────────────────────────────────────────

  List<Widget> _buildPieces(double boardW, double boardH) {
    final pieces = <Widget>[];
    final size = BoardLayout.pieceSize(boardW, boardH);
    final half = size / 2;

    for (int row = 0; row < game.boardState.length; row++) {
      final rowList = game.boardState[row];
      for (int col = 0; col < rowList.length; col++) {
        final piece = rowList[col];
        if (piece.isEmpty) continue;
        pieces.add(_positionedPiece(piece, row, col, boardW, boardH, size, half));
      }
    }
    return pieces;
  }

  Widget _positionedPiece(
    PieceModel piece,
    int row,
    int col,
    double boardW,
    double boardH,
    double size,
    double half,
  ) {
    final isSelected =
        uiState != null && uiState!.selectedRow == row && uiState!.selectedCol == col;

    // Selection ring expands the widget; account for the extra radius.
    final ringExtra = isSelected ? size * 0.14 : 0.0;
    final x = BoardLayout.intersectionX(col, boardW) - half - ringExtra;
    final y = BoardLayout.intersectionY(row, boardH) - half - ringExtra;

    Widget pieceWidget = PieceWidget(
      color: piece.color!,
      type: piece.type!,
      size: size,
      isSelected: isSelected,
    );

    if (onIntersectionTap != null) {
      pieceWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onIntersectionTap!(row, col),
        child: pieceWidget,
      );
    }

    return Positioned(left: x, top: y, child: pieceWidget);
  }

  // ── Coordinate math ────────────────────────────────────────────────────────

  /// Converts a pixel tap position to the nearest board (row, col).
  /// Returns null if outside the grid.
  (int, int)? _positionToRowCol(double px, double py, double boardW, double boardH) {
    final cellW = BoardLayout.cellWidth(boardW);
    final cellH = BoardLayout.cellHeight(boardH);

    final col = ((px / cellW) - BoardLayout.outerPaddingCells).round();
    final row = ((py / cellH) - BoardLayout.outerPaddingCells).round();

    if (row < 0 || row >= BoardLayout.ranks) return null;
    if (col < 0 || col >= BoardLayout.files) return null;
    return (row, col);
  }
}

