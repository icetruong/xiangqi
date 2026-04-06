import 'package:flutter/material.dart';

import '../../../core/utils/board_layout.dart';
import '../../../core/utils/board_visual_config.dart';
import '../../../data/models/move_model.dart';

/// Draws the web-style old-position marker for the most recent move.
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
  final double boardW;
  final double boardH;

  const _LastMovePainter({
    required this.fromRow,
    required this.fromCol,
    required this.boardW,
    required this.boardH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = BoardLayout.cellWidth(boardW);
    final radius =
        BoardVisualConfig.scaledPx(BoardVisualConfig.oldPosMarkerSizePx, cell) /
        2;

    final fillPaint = Paint()
      ..color = const Color(0xFFD35400)
      ..style = PaintingStyle.fill;

    final center = Offset(
      BoardLayout.intersectionX(fromCol, boardW),
      BoardLayout.intersectionY(fromRow, boardH),
    );

    canvas.drawCircle(center, radius, fillPaint);
  }

  @override
  bool shouldRepaint(_LastMovePainter oldDelegate) {
    return oldDelegate.fromRow != fromRow ||
        oldDelegate.fromCol != fromCol ||
        oldDelegate.boardW != boardW ||
        oldDelegate.boardH != boardH;
  }
}
