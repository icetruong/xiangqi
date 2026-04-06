import 'package:flutter/material.dart';
import '../../../core/utils/board_layout.dart';

/// Draws the Xiangqi board background using [CustomPainter].
///
/// Renders:
///   • Outer border (bounding rectangle of the intersection grid)
///   • 9 vertical file lines (broken at the river, except for edge files)
///   • 10 horizontal rank lines
///   • Palace diagonal lines
///   • Intersection marks (L-shapes) for Cannons and Pawns
///   • "楚河  漢界" river label centred in the river band
class BoardBackgroundPainter extends CustomPainter {
  const BoardBackgroundPainter();

  // ── Colour constants ──────────────────────────────────────────────────────

  // Wuxia aesthetic: ivory/parchment board, deep brown lines.
  static const _boardColor = Color(0xFFE8CFA6); 
  static const _lineColor = Color(0xFF5D4037);
  static const _riverTextColor = Color(0xFF4E342E);
  static const _borderColor = Color(0xFF3E2723);

  // ── Paint objects (created once, reused by painter) ───────────────────────

  static final _boardPaint = Paint()..color = _boardColor;
  static final _linePaint = Paint()
    ..color = _lineColor
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;
  static final _markPaint = Paint()
    ..color = _lineColor
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  static final _borderPaint = Paint()
    ..color = _borderColor
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid boundary: from first intersection to last intersection.
    final x0 = BoardLayout.intersectionX(0, w);
    final y0 = BoardLayout.intersectionY(0, h);
    final x8 = BoardLayout.intersectionX(BoardLayout.files - 1, w);
    final y9 = BoardLayout.intersectionY(BoardLayout.ranks - 1, h);
    final gridW = x8 - x0;
    final gridH = y9 - y0;

    // 1. Full canvas warm ivory fill
    canvas.drawRect(Offset.zero & size, _boardPaint);

    final riverTop = BoardLayout.intersectionY(4, h);
    final riverBottom = BoardLayout.intersectionY(5, h);

    // 2. Horizontal rank lines — run edge-to-edge within the grid.
    for (int row = 0; row < BoardLayout.ranks; row++) {
      final y = BoardLayout.intersectionY(row, h);
      canvas.drawLine(Offset(x0, y), Offset(x8, y), _linePaint);
    }

    // 3. Vertical file lines.
    for (int col = 0; col < BoardLayout.files; col++) {
      final x = BoardLayout.intersectionX(col, w);
      if (col == 0 || col == BoardLayout.files - 1) {
        // Edge files draw straight through
        canvas.drawLine(Offset(x, y0), Offset(x, y9), _linePaint);
      } else {
        // Inner files break at the river
        canvas.drawLine(Offset(x, y0), Offset(x, riverTop), _linePaint);
        canvas.drawLine(Offset(x, riverBottom), Offset(x, y9), _linePaint);
      }
    }

    // 4. Palace diagonals.
    // Black palace (top: ranks 0-2, files 3-5)
    final topPalaceY0 = y0;
    final topPalaceY2 = BoardLayout.intersectionY(2, h);
    final pX3 = BoardLayout.intersectionX(3, w);
    final pX5 = BoardLayout.intersectionX(5, w);
    canvas.drawLine(Offset(pX3, topPalaceY0), Offset(pX5, topPalaceY2), _linePaint);
    canvas.drawLine(Offset(pX5, topPalaceY0), Offset(pX3, topPalaceY2), _linePaint);

    // Red palace (bottom: ranks 7-9, files 3-5)
    final botPalaceY7 = BoardLayout.intersectionY(7, h);
    final botPalaceY9 = y9;
    canvas.drawLine(Offset(pX3, botPalaceY7), Offset(pX5, botPalaceY9), _linePaint);
    canvas.drawLine(Offset(pX5, botPalaceY7), Offset(pX3, botPalaceY9), _linePaint);

    // 5. Normal lines around the inner intersection grid.
    canvas.drawRect(Rect.fromLTWH(x0, y0, gridW, gridH), _linePaint);

    // Outer thick framing border around the entire widget (outside all pieces).
    final outerRect = Rect.fromLTWH(0, 0, w, h).deflate(1.5);
    canvas.drawRect(outerRect, _borderPaint);
    // Draw an extra inner trim for the outer frame for premium look
    canvas.drawRect(outerRect.deflate(4.0), Paint()..color = _lineColor..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // 6. Intersection marks (Cannons & Pawns).
    _drawAllMarks(canvas, w, h);

    // 7. River label.
    _drawRiverLabel(canvas, x0, gridW, riverTop, riverBottom);
  }

  void _drawAllMarks(Canvas canvas, double w, double h) {
    // Pawns
    for (int col = 0; col < BoardLayout.files; col += 2) {
      bool left = col > 0;
      bool right = col < BoardLayout.files - 1;
      // Black pawns at rank 3
      _drawIntersectionMarks(canvas, w, h, col, 3, left, right);
      // Red pawns at rank 6
      _drawIntersectionMarks(canvas, w, h, col, 6, left, right);
    }
    // Cannons
    // Black cannons at rank 2, files 1 and 7
    _drawIntersectionMarks(canvas, w, h, 1, 2, true, true);
    _drawIntersectionMarks(canvas, w, h, 7, 2, true, true);
    // Red cannons at rank 7, files 1 and 7
    _drawIntersectionMarks(canvas, w, h, 1, 7, true, true);
    _drawIntersectionMarks(canvas, w, h, 7, 7, true, true);
  }

  void _drawIntersectionMarks(Canvas canvas, double w, double h, int col, int row, bool left, bool right) {
    final x = BoardLayout.intersectionX(col, w);
    final y = BoardLayout.intersectionY(row, h);
    final double gap = w * 0.015;
    final double len = w * 0.025;

    if (left) {
      // Top left
      canvas.drawLine(Offset(x - gap, y - gap), Offset(x - gap - len, y - gap), _markPaint);
      canvas.drawLine(Offset(x - gap, y - gap), Offset(x - gap, y - gap - len), _markPaint);
      // Bottom left
      canvas.drawLine(Offset(x - gap, y + gap), Offset(x - gap - len, y + gap), _markPaint);
      canvas.drawLine(Offset(x - gap, y + gap), Offset(x - gap, y + gap + len), _markPaint);
    }

    if (right) {
      // Top right
      canvas.drawLine(Offset(x + gap, y - gap), Offset(x + gap + len, y - gap), _markPaint);
      canvas.drawLine(Offset(x + gap, y - gap), Offset(x + gap, y - gap - len), _markPaint);
      // Bottom right
      canvas.drawLine(Offset(x + gap, y + gap), Offset(x + gap + len, y + gap), _markPaint);
      canvas.drawLine(Offset(x + gap, y + gap), Offset(x + gap, y + gap + len), _markPaint);
    }
  }

  void _drawRiverLabel(
    Canvas canvas,
    double gridOriginX,
    double gridWidth,
    double riverTop,
    double riverBottom,
  ) {
    final centreY = (riverTop + riverBottom) / 2;
    final fontSize = (riverBottom - riverTop) * 0.45;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '楚河              漢界',
        style: TextStyle(
          color: _riverTextColor,
          fontSize: fontSize,
          fontFamily: 'serif',
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: gridWidth);

    textPainter.paint(
      canvas,
      Offset(
        gridOriginX + (gridWidth - textPainter.width) / 2,
        centreY - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stateless widget wrapper around [BoardBackgroundPainter].
///
/// Callers can embed this directly inside a [Stack] as the bottom layer.
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
