import 'package:flutter/material.dart';
import '../../../core/utils/board_layout.dart';
import '../../../data/models/move_model.dart';

/// Draws a pair of hollow rings on the board marking the from/to squares of
/// the most recent move — works for both player moves and AI moves.
///
/// Drop this widget directly into the board [Stack] as a layer above
/// [BoardBackground] and below the piece layer.
class LastMoveOverlay extends StatelessWidget {
  final MoveModel? lastMove;
  final double boardW;
  final double boardH;

  const LastMoveOverlay({
    super.key,
    required this.lastMove,
    required this.boardW,
    required this.boardH,
  });

  @override
  Widget build(BuildContext context) {
    final move = lastMove;
    if (move == null) return const SizedBox.shrink();

    return CustomPaint(
      painter: _LastMovePainter(
        fromRow: move.from[0],
        fromCol: move.from[1],
        toRow: move.to[0],
        toCol: move.to[1],
        boardW: boardW,
        boardH: boardH,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LastMovePainter extends CustomPainter {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final double boardW;
  final double boardH;

  // Amber gold — reads clearly on the warm board background.
  static const _color = Color(0xFFFFB300);

  const _LastMovePainter({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.boardW,
    required this.boardH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = BoardLayout.pieceSize(boardW, boardH) * 0.52;

    final paint = Paint()
      ..color = _color.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.18;

    final fillPaint = Paint()
      ..color = _color.withAlpha(45)
      ..style = PaintingStyle.fill;

    _drawMarker(canvas, fromRow, fromCol, radius, paint, fillPaint);
    _drawMarker(canvas, toRow, toCol, radius, paint, fillPaint);
  }

  void _drawMarker(
    Canvas canvas,
    int row,
    int col,
    double radius,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    final center = Offset(
      BoardLayout.intersectionX(col, boardW),
      BoardLayout.intersectionY(row, boardH),
    );
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, strokePaint);
  }

  @override
  bool shouldRepaint(_LastMovePainter old) =>
      old.fromRow != fromRow ||
      old.fromCol != fromCol ||
      old.toRow != toRow ||
      old.toCol != toCol;
}
