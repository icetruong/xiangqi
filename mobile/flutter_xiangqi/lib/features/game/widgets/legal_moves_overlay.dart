import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/utils/board_layout.dart';
import '../../../core/utils/board_visual_config.dart';

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
    final cell = BoardLayout.cellWidth(boardW);
    final dotRadius =
        BoardVisualConfig.scaledPx(BoardVisualConfig.hintDotSizePx, cell) / 2;

    final fillPaint = Paint()
      ..color = _dotColor.withAlpha(180)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = _dotColor.withAlpha(60)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        BoardVisualConfig.scaledPx(6, cell) * 0.5,
      );

    for (final dest in legalMoves) {
      if (dest.length < 2) continue;

      final center = Offset(
        BoardLayout.intersectionX(dest[1], boardW),
        BoardLayout.intersectionY(dest[0], boardH),
      );

      canvas.drawCircle(center, dotRadius, glowPaint);
      canvas.drawCircle(center, dotRadius, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_LegalMovesPainter oldDelegate) {
    return oldDelegate.legalMoves != legalMoves;
  }
}
