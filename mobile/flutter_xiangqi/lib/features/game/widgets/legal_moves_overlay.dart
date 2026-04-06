import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/utils/board_layout.dart';

/// Draws small filled dots on valid destination squares for the currently
/// selected piece, using backend-provided legal move data.
class LegalMovesOverlay extends StatelessWidget {
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

  static const _dotColor = XiangqiColors.hintOrange;

  const _LegalMovesPainter({
    required this.legalMoves,
    required this.boardW,
    required this.boardH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pieceRadius = BoardLayout.pieceSize(boardW, boardH) / 2;
    final dotRadius = pieceRadius * 0.28;

    final fillPaint = Paint()
      ..color = _dotColor.withAlpha(180)
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = _dotColor.withAlpha(230)
      ..style = PaintingStyle.stroke
      ..strokeWidth = dotRadius * 0.22;

    for (final dest in legalMoves) {
      if (dest.length < 2) continue;

      final center = Offset(
        BoardLayout.intersectionX(dest[1], boardW),
        BoardLayout.intersectionY(dest[0], boardH),
      );

      canvas.drawCircle(center, dotRadius, fillPaint);
      canvas.drawCircle(center, dotRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(_LegalMovesPainter oldDelegate) {
    return oldDelegate.legalMoves != legalMoves;
  }
}
