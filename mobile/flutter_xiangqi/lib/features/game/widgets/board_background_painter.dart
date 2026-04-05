import 'package:flutter/material.dart';
import '../../../core/utils/board_layout.dart';

/// Draws the Xiangqi board background using [CustomPainter].
///
/// Renders:
///   • Outer border (bounding rectangle of the intersection grid)
///   • 9 vertical file lines
///   • 10 horizontal rank lines
///   • River band (slightly tinted area between rows 4 and 5)
///   • "楚河  漢界" river label centred in the river band
///
/// The painter is entirely stateless and size-responsive: it uses
/// [BoardLayout] to derive all coordinates from the canvas size.
class BoardBackgroundPainter extends CustomPainter {
  const BoardBackgroundPainter();

  // ── Colour constants ──────────────────────────────────────────────────────

  static const _boardColor = Color(0xFFF5CBA7); // warm wood tone
  static const _lineColor = Color(0xFF6D4C41);
  static const _riverColor = Color(0xFFCCE5F3); // subtle blue tint
  static const _riverTextColor = Color(0xFF1A237E);
  static const _borderColor = Color(0xFF4E342E);

  // ── Paint objects (created once, reused by painter) ───────────────────────

  static final _boardPaint = Paint()..color = _boardColor;
  static final _linePaint = Paint()
    ..color = _lineColor
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;
  static final _borderPaint = Paint()
    ..color = _borderColor
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;
  static final _riverPaint = Paint()
    ..color = _riverColor
    ..style = PaintingStyle.fill;

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

    // 1. Full canvas warm-wood fill (covers the outer padding fringe too).
    canvas.drawRect(Offset.zero & size, _boardPaint);

    // 2. River band (spans the full grid width).
    final riverTop = BoardLayout.riverTop(h);
    final riverBottom = BoardLayout.riverBottom(h);
    canvas.drawRect(
      Rect.fromLTWH(x0, riverTop, gridW, riverBottom - riverTop),
      _riverPaint,
    );

    // 3. Horizontal rank lines — run edge-to-edge within the grid.
    for (int row = 0; row < BoardLayout.ranks; row++) {
      final y = BoardLayout.intersectionY(row, h);
      canvas.drawLine(Offset(x0, y), Offset(x8, y), _linePaint);
    }

    // 4. Vertical file lines — run edge-to-edge within the grid.
    for (int col = 0; col < BoardLayout.files; col++) {
      final x = BoardLayout.intersectionX(col, w);
      canvas.drawLine(Offset(x, y0), Offset(x, y9), _linePaint);
    }

    // 5. Outer border around the intersection grid only.
    canvas.drawRect(
      Rect.fromLTWH(x0, y0, gridW, gridH),
      _borderPaint,
    );

    // 6. River label.
    _drawRiverLabel(canvas, x0, gridW, riverTop, riverBottom);
  }

  void _drawRiverLabel(
    Canvas canvas,
    double gridOriginX,
    double gridWidth,
    double riverTop,
    double riverBottom,
  ) {
    final centreY = (riverTop + riverBottom) / 2;
    final fontSize = (riverBottom - riverTop) * 0.55;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '楚河          漢界',
        style: TextStyle(
          color: _riverTextColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
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
