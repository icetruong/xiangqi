import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared visual metrics copied from the web board renderer.
///
/// The web board is built from:
///   - `CELL_SIZE = 64`
///   - `BOARD_PAD = 32`
///   - wrapper padding `18 18 20`
/// These values are scaled proportionally in Flutter so the portrait board
/// keeps the same internal proportions as the web source of truth.
class BoardVisualConfig {
  BoardVisualConfig._();

  static const int files = 9;
  static const int ranks = 10;

  static const double webCellSize = 64;
  static const double webBoardPad = 32;

  static const double innerBoardWidth =
      (files - 1) * webCellSize + webBoardPad * 2;
  static const double innerBoardHeight =
      (ranks - 1) * webCellSize + webBoardPad * 2;

  static const double framePadLeft = 18;
  static const double framePadTop = 18;
  static const double framePadRight = 18;
  static const double framePadBottom = 20;

  static const double wrapperWidth =
      innerBoardWidth + framePadLeft + framePadRight;
  static const double wrapperHeight =
      innerBoardHeight + framePadTop + framePadBottom;

  static const double innerAspectRatio = innerBoardWidth / innerBoardHeight;
  static const double wrapperAspectRatio = wrapperWidth / wrapperHeight;

  static const double pieceSizeRatio = 0.82;
  static const double pieceFontSizeRatio = 0.58;

  static const double gridStrokePx = 1.2;
  static const double gridThinStrokePx = 0.9;
  static const double cornerMarkGapPx = 4;
  static const double cornerMarkLengthPx = 10;

  static const double riverTextFontPx = 28;
  static const double riverTextLetterSpacingPx = 7;
  static const double riverTextOffsetYPx = 11;
  static const double riverTextLeftCol = 1.8;
  static const double riverTextRightCol = 6.2;

  static const double wrapperInnerRuleInsetPx = 8;
  static const double rodOverflowPx = 10;
  static const double rodHeightPx = 9;
  static const double rodKnobSizePx = 15;
  static const double rodKnobOffsetPx = 4;
  static const double cornerInsetPx = 11;
  static const double cornerFontSizePx = 8.8;

  static const double hintDotSizePx = 14;
  static const double oldPosMarkerSizePx = 12;

  static const double pieceRingOuterPx = 3;
  static const double pieceRingRimPx = 5;
  static const double pieceRingBorderPx = 6;
  static const double pieceShadowBlurPx = 10;
  static const double pieceShadowOffsetYPx = 4;
  static const double pieceSelectedLiftPx = 2;
  static const double pieceSelectedRingPx = 9;
  static const double pieceSelectedGlowPx = 18;
  static const double pieceSelectedShadowBlurPx = 16;
  static const double pieceSelectedShadowOffsetYPx = 6;
  static const double pieceLastMoveInsetPx = 4;
  static const double pieceLastMoveStrokePx = 2.5;
  static const double pieceLastMoveGlowPx = 8;
  static const double pieceCaptureInsetPx = 6;
  static const double pieceCaptureGlowNearPx = 10;
  static const double pieceCaptureGlowFarPx = 20;
  static const double kingCheckRingPx = 9;
  static const double kingCheckGlowPx = 20;
  static const double pieceGlossTopBlurPx = 4;
  static const double pieceGlossBottomBlurPx = 4;

  static double wrapperScale(Size size) =>
      math.min(size.width / wrapperWidth, size.height / wrapperHeight);

  static EdgeInsets boardInsets(Size wrapperSize) {
    final scale = wrapperScale(wrapperSize);
    return EdgeInsets.fromLTRB(
      framePadLeft * scale,
      framePadTop * scale,
      framePadRight * scale,
      framePadBottom * scale,
    );
  }

  static EdgeInsets innerRuleInsets(Size wrapperSize) {
    final inset = wrapperScale(wrapperSize) * wrapperInnerRuleInsetPx;
    return EdgeInsets.all(inset);
  }

  static double scaledPx(double px, double boardCell) {
    return px * (boardCell / webCellSize);
  }
}
