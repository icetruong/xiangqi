import 'dart:ui';

/// Pure math/layout utility for a standard Xiangqi board.
///
/// Xiangqi board layout:
///   - 9 files  (columns 0–8)
///   - 10 ranks (rows 0–9, row 0 = black back rank, row 9 = red back rank)
///   - Pieces sit on intersections, NOT cell centres.
///   - There are 8 column gaps and 9 row gaps between intersections.
///
/// Outer padding model:
///   The drawable canvas is wider/taller than the intersection grid by one
///   full cell on each axis (half a cell on each side).  This ensures pieces
///   on the outer intersections are never clipped by the widget boundary.
///
/// All methods are pure; none carry game-rule knowledge.
class BoardLayout {
  // ── Board constants ──────────────────────────────────────────────────────

  /// Number of files (vertical lines) = number of columns of intersections.
  static const int files = 9;

  /// Number of ranks (horizontal lines) = number of rows of intersections.
  static const int ranks = 10;

  /// Number of gaps between adjacent columns.
  static const int columnGaps = files - 1; // 8

  /// Number of gaps between adjacent rows.
  static const int rowGaps = ranks - 1; // 9

  /// Half-cell padding fraction added on each side of the grid.
  ///
  /// The total canvas width spans (columnGaps + 2 * outerPaddingCells) cells
  /// wide.  Keeping this at 0.5 means one full cell of breathing room is split
  /// equally left/right and top/bottom.
  static const double outerPaddingCells = 0.5;

  /// Total canvas width in "cell" units.
  static const double totalWidthCells = columnGaps + 2 * outerPaddingCells;

  /// Total canvas height in "cell" units.
  static const double totalHeightCells = rowGaps + 2 * outerPaddingCells;

  /// Aspect ratio (width : height) of the full canvas including outer padding.
  static const double aspectRatio = totalWidthCells / totalHeightCells;
  // ≈ (8 + 1) / (9 + 1) = 9/10 = 0.900

  // ── Interval helpers ─────────────────────────────────────────────────────

  /// Horizontal distance between two adjacent column intersections,
  /// derived from the total canvas [width].
  static double cellWidth(double width) => width / totalWidthCells;

  /// Vertical distance between two adjacent row intersections,
  /// derived from the total canvas [height].
  static double cellHeight(double height) => height / totalHeightCells;

  // ── Position helpers ─────────────────────────────────────────────────────

  /// X coordinate of the intersection at [col] (0-indexed).
  ///
  /// Returns a value inside the canvas with [outerPaddingCells] margin on
  /// the left, so col 0 and col 8 are always inset from the widget edge.
  static double intersectionX(int col, double width) {
    return (col + outerPaddingCells) * cellWidth(width);
  }

  /// Y coordinate of the intersection at [row] (0-indexed).
  ///
  /// Row 0 and row 9 are inset from the top/bottom edge by [outerPaddingCells].
  static double intersectionY(int row, double height) {
    return (row + outerPaddingCells) * cellHeight(height);
  }

  /// Offset of the intersection at ([row], [col]).
  static Offset intersectionOffset(
    int row,
    int col,
    double width,
    double height,
  ) {
    return Offset(intersectionX(col, width), intersectionY(row, height));
  }

  // ── Piece sizing ─────────────────────────────────────────────────────────

  /// Recommended piece diameter.
  ///
  /// 0.92 of the smaller cell dimension makes the pieces sit tighter on the
  /// board while still keeping a thin visual gap between adjacent tokens.
  static double pieceSize(double width, double height) {
    final cw = cellWidth(width);
    final ch = cellHeight(height);
    return (cw < ch ? cw : ch) * 0.98;
  }

  // ── River ────────────────────────────────────────────────────────────────

  /// Y coordinate of the top edge of the river band (between rows 4 and 5).
  static double riverTop(double height) => intersectionY(4, height);

  /// Y coordinate of the bottom edge of the river band.
  static double riverBottom(double height) => intersectionY(5, height);

  /// Centre Y of the river band.
  static double riverCentreY(double height) =>
      (riverTop(height) + riverBottom(height)) / 2;
}
