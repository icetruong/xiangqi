import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/utils/board_layout.dart';

/// Draws the Xiangqi board background using [CustomPainter].
class BoardBackgroundPainter extends CustomPainter {
  const BoardBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final x0 = BoardLayout.intersectionX(0, w);
    final y0 = BoardLayout.intersectionY(0, h);
    final x8 = BoardLayout.intersectionX(BoardLayout.files - 1, w);
    final y9 = BoardLayout.intersectionY(BoardLayout.ranks - 1, h);
    final gridRect = Rect.fromLTRB(x0, y0, x8, y9);
    final riverTop = BoardLayout.riverTop(h);
    final riverBottom = BoardLayout.riverBottom(h);
    final cell = math.min(BoardLayout.cellWidth(w), BoardLayout.cellHeight(h));

    _paintBoardSurface(canvas, size);
    _paintRiverBand(canvas, gridRect, riverTop, riverBottom);
    _drawGrid(canvas, w, h, gridRect, riverTop, riverBottom, cell);
    _drawAllMarks(canvas, w, h, cell);
    _drawRiverLabel(canvas, w, riverTop, riverBottom);
  }

  void _paintBoardSurface(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, size.height),
          const [
            XiangqiColors.boardBgLight,
            XiangqiColors.boardBg,
            XiangqiColors.boardBgLight,
          ],
          const [0.0, 0.5, 1.0],
        ),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width / 2, size.height / 2),
          math.max(size.width, size.height) * 0.78,
          [Colors.transparent, XiangqiColors.boardFrameDark.withAlpha(22)],
          const [0.62, 1.0],
        ),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.18),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, size.height * 0.18),
          [Colors.white.withAlpha(28), Colors.transparent],
        ),
    );
  }

  void _paintRiverBand(
    Canvas canvas,
    Rect gridRect,
    double riverTop,
    double riverBottom,
  ) {
    canvas.drawRect(
      Rect.fromLTRB(gridRect.left, riverTop, gridRect.right, riverBottom),
      Paint()..color = XiangqiColors.boardFrameDark.withAlpha(14),
    );
  }

  void _drawGrid(
    Canvas canvas,
    double w,
    double h,
    Rect gridRect,
    double riverTop,
    double riverBottom,
    double cell,
  ) {
    final linePaint = Paint()
      ..color = XiangqiColors.gridStroke
      ..strokeWidth = _clamp(cell * 0.024, 1.0, 1.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final thinPaint = Paint()
      ..color = XiangqiColors.gridStroke
      ..strokeWidth = _clamp(cell * 0.02, 0.9, 1.1)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int row = 0; row < BoardLayout.ranks; row++) {
      final y = BoardLayout.intersectionY(row, h);
      canvas.drawLine(
        Offset(gridRect.left, y),
        Offset(gridRect.right, y),
        linePaint,
      );
    }

    for (int col = 0; col < BoardLayout.files; col++) {
      final x = BoardLayout.intersectionX(col, w);
      if (col == 0 || col == BoardLayout.files - 1) {
        canvas.drawLine(
          Offset(x, gridRect.top),
          Offset(x, gridRect.bottom),
          linePaint,
        );
      } else {
        canvas.drawLine(
          Offset(x, gridRect.top),
          Offset(x, riverTop),
          linePaint,
        );
        canvas.drawLine(
          Offset(x, riverBottom),
          Offset(x, gridRect.bottom),
          linePaint,
        );
      }
    }

    canvas.drawRect(gridRect, linePaint);

    final pX3 = BoardLayout.intersectionX(3, w);
    final pX5 = BoardLayout.intersectionX(5, w);
    final topPalaceBottom = BoardLayout.intersectionY(2, h);
    final bottomPalaceTop = BoardLayout.intersectionY(7, h);

    canvas.drawLine(
      Offset(pX3, gridRect.top),
      Offset(pX5, topPalaceBottom),
      thinPaint,
    );
    canvas.drawLine(
      Offset(pX5, gridRect.top),
      Offset(pX3, topPalaceBottom),
      thinPaint,
    );
    canvas.drawLine(
      Offset(pX3, bottomPalaceTop),
      Offset(pX5, gridRect.bottom),
      thinPaint,
    );
    canvas.drawLine(
      Offset(pX5, bottomPalaceTop),
      Offset(pX3, gridRect.bottom),
      thinPaint,
    );
  }

  void _drawAllMarks(Canvas canvas, double w, double h, double cell) {
    for (int col = 0; col < BoardLayout.files; col += 2) {
      final hasLeft = col > 0;
      final hasRight = col < BoardLayout.files - 1;
      _drawIntersectionMarks(canvas, w, h, col, 3, hasLeft, hasRight, cell);
      _drawIntersectionMarks(canvas, w, h, col, 6, hasLeft, hasRight, cell);
    }

    _drawIntersectionMarks(canvas, w, h, 1, 2, true, true, cell);
    _drawIntersectionMarks(canvas, w, h, 7, 2, true, true, cell);
    _drawIntersectionMarks(canvas, w, h, 1, 7, true, true, cell);
    _drawIntersectionMarks(canvas, w, h, 7, 7, true, true, cell);
  }

  void _drawIntersectionMarks(
    Canvas canvas,
    double w,
    double h,
    int col,
    int row,
    bool left,
    bool right,
    double cell,
  ) {
    final x = BoardLayout.intersectionX(col, w);
    final y = BoardLayout.intersectionY(row, h);
    final gap = cell * 0.16;
    final len = cell * 0.24;
    final paint = Paint()
      ..color = XiangqiColors.gridStroke
      ..strokeWidth = _clamp(cell * 0.022, 0.9, 1.2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (left) {
      canvas.drawLine(
        Offset(x - gap, y - gap),
        Offset(x - gap - len, y - gap),
        paint,
      );
      canvas.drawLine(
        Offset(x - gap, y - gap),
        Offset(x - gap, y - gap - len),
        paint,
      );
      canvas.drawLine(
        Offset(x - gap, y + gap),
        Offset(x - gap - len, y + gap),
        paint,
      );
      canvas.drawLine(
        Offset(x - gap, y + gap),
        Offset(x - gap, y + gap + len),
        paint,
      );
    }

    if (right) {
      canvas.drawLine(
        Offset(x + gap, y - gap),
        Offset(x + gap + len, y - gap),
        paint,
      );
      canvas.drawLine(
        Offset(x + gap, y - gap),
        Offset(x + gap, y - gap - len),
        paint,
      );
      canvas.drawLine(
        Offset(x + gap, y + gap),
        Offset(x + gap + len, y + gap),
        paint,
      );
      canvas.drawLine(
        Offset(x + gap, y + gap),
        Offset(x + gap, y + gap + len),
        paint,
      );
    }
  }

  void _drawRiverLabel(
    Canvas canvas,
    double width,
    double riverTop,
    double riverBottom,
  ) {
    final riverHeight = riverBottom - riverTop;
    final centerY = (riverTop + riverBottom) / 2;
    final fontSize = riverHeight * 0.5;
    final style = TextStyle(
      color: XiangqiColors.riverText.withAlpha(112),
      fontSize: fontSize,
      fontFamily: 'serif',
      fontWeight: FontWeight.w700,
      letterSpacing: fontSize * 0.22,
      height: 1,
    );

    final left = TextPainter(
      text: TextSpan(text: '\u695A\u6CB3', style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final right = TextPainter(
      text: TextSpan(text: '\u6F22\u754C', style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final leftX = BoardLayout.intersectionX(2, width) - left.width / 2;
    final rightX = BoardLayout.intersectionX(6, width) - right.width / 2;
    final textY = centerY - left.height / 2 + riverHeight * 0.06;

    left.paint(canvas, Offset(leftX, textY));
    right.paint(canvas, Offset(rightX, textY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

double _clamp(double value, double min, double max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

/// Stateless widget wrapper around [BoardBackgroundPainter].
class BoardBackground extends StatelessWidget {
  const BoardBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const BoardBackgroundPainter(),
      child: const SizedBox.expand(),
    );
  }
}
