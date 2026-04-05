import 'package:flutter/material.dart';
import '../../../core/utils/board_layout.dart';

/// Draws small filled dots on valid destination squares for the currently
/// selected piece, using backend-provided legal move data.
///
/// Only visible when [legalMoves] is non-null and non-empty.
/// Drop into the board [Stack] above [LastMoveOverlay] and below pieces.
class LegalMovesOverlay extends StatelessWidget {
  /// Pre-filtered list of `[row, col]` destinations for the selected piece.
  /// Each entry is a two-element list: `[row, col]`.
  final List<List<int>>? legalMoves;
  final double boardW;
  final double boardH;

  const LegalMovesOverlay({
    super.key,
    required this.legalMoves,
    required this.boardW,
    required this.boardH,
  });

  @override
  Widget build(BuildContext context) {
    final moves = legalMoves;
    if (moves == null || moves.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: _LegalMovesPainter(
        legalMoves: moves,
        boardW: boardW,
        boardH: boardH,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LegalMovesPainter extends CustomPainter {
  final List<List<int>> legalMoves;
  final double boardW;
  final double boardH;

  // Translucent green dot — clearly visible but not distracting.
  static const _dotColor = Color(0xFF00C853);

  const _LegalMovesPainter({
    required this.legalMoves,
    required this.boardW,
    required this.boardH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pieceR = BoardLayout.pieceSize(boardW, boardH) / 2;
    final dotR = pieceR * 0.38; // smaller than a piece

    final fillPaint = Paint()
      ..color = _dotColor.withAlpha(170)
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = _dotColor.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = dotR * 0.25;

    for (final dest in legalMoves) {
      if (dest.length < 2) continue;
      final center = Offset(
        BoardLayout.intersectionX(dest[1], boardW),
        BoardLayout.intersectionY(dest[0], boardH),
      );
      canvas.drawCircle(center, dotR, fillPaint);
      canvas.drawCircle(center, dotR, ringPaint);
    }
  }

  @override
  bool shouldRepaint(_LegalMovesPainter old) => old.legalMoves != legalMoves;
}
