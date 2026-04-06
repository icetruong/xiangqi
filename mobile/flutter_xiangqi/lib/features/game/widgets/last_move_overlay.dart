import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/utils/board_layout.dart';
import '../../../data/models/move_model.dart';

/// Draws a pair of rings on the board marking the most recent move.
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

  static const _color = XiangqiColors.hintOrange;

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
    final radius = BoardLayout.pieceSize(boardW, boardH) * 0.54;

    final strokePaint = Paint()
      ..color = _color.withAlpha(210)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14;

    final glowPaint = Paint()
      ..color = _color.withAlpha(52)
      ..style = PaintingStyle.fill;

    _drawMarker(canvas, fromRow, fromCol, radius, strokePaint, glowPaint);
    _drawMarker(canvas, toRow, toCol, radius, strokePaint, glowPaint);
  }

  void _drawMarker(
    Canvas canvas,
    int row,
    int col,
    double radius,
    Paint strokePaint,
    Paint glowPaint,
  ) {
    final center = Offset(
      BoardLayout.intersectionX(col, boardW),
      BoardLayout.intersectionY(row, boardH),
    );

    canvas.drawCircle(center, radius, glowPaint);
    canvas.drawCircle(center, radius, strokePaint);
  }

  @override
  bool shouldRepaint(_LastMovePainter oldDelegate) {
    return oldDelegate.fromRow != fromRow ||
        oldDelegate.fromCol != fromCol ||
        oldDelegate.toRow != toRow ||
        oldDelegate.toCol != toCol;
  }
}
