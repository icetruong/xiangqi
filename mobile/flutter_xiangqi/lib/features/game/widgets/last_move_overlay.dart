import 'package:flutter/material.dart';

import '../../../core/utils/board_layout.dart';
import '../../../core/utils/board_visual_config.dart';
import '../../../data/models/move_model.dart';

/// Draws the web-style source marker and/or target ring for the most recent move.
class LastMoveOverlay extends StatelessWidget {
  final MoveModel? lastMove;
  final double boardW;
  final double boardH;
  final bool showSourceMarker;
  final bool showTargetRing;

  const LastMoveOverlay({
    super.key,
    required this.lastMove,
    required this.boardW,
    required this.boardH,
    this.showSourceMarker = true,
    this.showTargetRing = false,
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
        showSourceMarker: showSourceMarker,
        showTargetRing: showTargetRing,
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
  final bool showSourceMarker;
  final bool showTargetRing;

  const _LastMovePainter({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.boardW,
    required this.boardH,
    required this.showSourceMarker,
    required this.showTargetRing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = BoardLayout.cellWidth(boardW);
    if (showSourceMarker) {
      final radius =
          BoardVisualConfig.scaledPx(
            BoardVisualConfig.oldPosMarkerSizePx,
            cell,
          ) /
          2;
      final center = Offset(
        BoardLayout.intersectionX(fromCol, boardW),
        BoardLayout.intersectionY(fromRow, boardH),
      );

      final glowPaint = Paint()
        ..color = const Color(0x80D35400)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          Shadow.convertRadiusToSigma(radius * 0.75),
        );

      final fillPaint = Paint()
        ..color = const Color(0xFFD35400)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, glowPaint);
      canvas.drawCircle(center, radius, fillPaint);
    }

    if (showTargetRing) {
      final pieceSize = BoardLayout.pieceSize(boardW, boardH);
      final inset = BoardVisualConfig.scaledPx(
        BoardVisualConfig.pieceLastMoveInsetPx,
        cell,
      );
      final stroke = BoardVisualConfig.scaledPx(
        BoardVisualConfig.pieceLastMoveStrokePx,
        cell,
      );
      final glow = BoardVisualConfig.scaledPx(
        BoardVisualConfig.pieceLastMoveGlowPx,
        cell,
      );
      final radius = pieceSize / 2 + inset + stroke / 2;
      final center = Offset(
        BoardLayout.intersectionX(toCol, boardW),
        BoardLayout.intersectionY(toRow, boardH),
      );

      final glowPaint = Paint()
        ..color = const Color(0x99E67E22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          Shadow.convertRadiusToSigma(glow),
        );

      final strokePaint = Paint()
        ..color = const Color(0xFFE67E22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;

      canvas.drawCircle(center, radius, glowPaint);
      canvas.drawCircle(center, radius, strokePaint);
    }
  }

  @override
  bool shouldRepaint(_LastMovePainter oldDelegate) {
    return oldDelegate.fromRow != fromRow ||
        oldDelegate.fromCol != fromCol ||
        oldDelegate.toRow != toRow ||
        oldDelegate.toCol != toCol ||
        oldDelegate.boardW != boardW ||
        oldDelegate.boardH != boardH ||
        oldDelegate.showSourceMarker != showSourceMarker ||
        oldDelegate.showTargetRing != showTargetRing;
  }
}
