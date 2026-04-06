import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../core/utils/board_visual_config.dart';
import '../../../core/utils/piece_mapper.dart';

/// Renders a single Xiangqi piece using the same coin treatment as the web UI.
class PieceWidget extends StatelessWidget {
  final String color;
  final String type;
  final double size;
  final bool isSelected;
  final bool isCaptureTarget;
  final bool isInCheck;

  const PieceWidget({
    super.key,
    required this.color,
    required this.type,
    required this.size,
    this.isSelected = false,
    this.isCaptureTarget = false,
    this.isInCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    final lift = isSelected
        ? _piecePx(BoardVisualConfig.pieceSelectedLiftPx)
        : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Transform.translate(
        offset: Offset(0, -lift),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (isInCheck)
              _StatusRing(
                size: size,
                spreadPx: BoardVisualConfig.kingCheckRingPx,
                glowPx: BoardVisualConfig.kingCheckGlowPx,
                color: const Color(0xFFDC2626),
                glowColor: const Color(0x99DC2626),
              )
            else if (isSelected)
              _StatusRing(
                size: size,
                spreadPx: BoardVisualConfig.pieceSelectedRingPx,
                glowPx: BoardVisualConfig.pieceSelectedGlowPx,
                color: XiangqiColors.highlightGold,
                glowColor: XiangqiColors.highlightGold.withAlpha(128),
              ),
            _CoinFace(
              color: color,
              type: type,
              size: size,
              piecePx: _piecePx,
              lifted: isSelected,
            ),
            if (isCaptureTarget)
              _OutlineRing(
                size: size,
                insetPx: BoardVisualConfig.pieceCaptureInsetPx,
                strokePx: BoardVisualConfig.pieceLastMoveStrokePx,
                color: const Color(0xFF8B5CF6),
                glowPx: BoardVisualConfig.pieceCaptureGlowNearPx,
                glowColor: const Color(0x8C8B5CF6),
                glowPxFar: BoardVisualConfig.pieceCaptureGlowFarPx,
                glowColorFar: const Color(0x408B5CF6),
              ),
          ],
        ),
      ),
    );
  }

  double _piecePx(double px) {
    final basePieceSize =
        BoardVisualConfig.webCellSize * BoardVisualConfig.pieceSizeRatio;
    return px * (size / basePieceSize);
  }
}

class _CoinFace extends StatelessWidget {
  final String color;
  final String type;
  final double size;
  final double Function(double px) piecePx;
  final bool lifted;

  const _CoinFace({
    required this.color,
    required this.type,
    required this.size,
    required this.piecePx,
    required this.lifted,
  });

  @override
  Widget build(BuildContext context) {
    final isRed = color == 'r';
    final label = PieceMapper.chineseLabel(color, type);
    final outerColor = isRed
        ? XiangqiColors.pieceRedOuter
        : XiangqiColors.pieceBlackOuter;
    final innerColor = isRed
        ? XiangqiColors.pieceRedInner
        : XiangqiColors.pieceBlackInner;
    final highlightColor = isRed
        ? XiangqiColors.pieceRedHighlight
        : XiangqiColors.pieceBlackHighlight;
    final borderColor = isRed
        ? const Color(0xFF8B1A1A)
        : const Color(0xFF111111);
    final textColor = isRed ? Colors.white : const Color(0xFFE8E0D0);
    final shadowColor = Colors.black.withAlpha(isRed ? 102 : 128);
    final topGloss = isRed
        ? Colors.white.withAlpha(64)
        : Colors.white.withAlpha(38);
    final bottomShade = isRed
        ? Colors.black.withAlpha(38)
        : Colors.black.withAlpha(51);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.24, -0.36),
                radius: 0.82,
                colors: [highlightColor, innerColor, outerColor],
                stops: const [0.0, 0.4, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: piecePx(BoardVisualConfig.pieceShadowBlurPx),
                  offset: Offset(
                    0,
                    piecePx(
                      lifted
                          ? BoardVisualConfig.pieceSelectedShadowOffsetYPx
                          : BoardVisualConfig.pieceShadowOffsetYPx,
                    ),
                  ),
                ),
                BoxShadow(
                  color: borderColor,
                  spreadRadius: piecePx(BoardVisualConfig.pieceRingBorderPx),
                ),
                BoxShadow(
                  color: XiangqiColors.pieceRim,
                  spreadRadius: piecePx(BoardVisualConfig.pieceRingRimPx),
                ),
                BoxShadow(
                  color: outerColor,
                  spreadRadius: piecePx(BoardVisualConfig.pieceRingOuterPx),
                ),
              ],
            ),
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: size * 0.12,
            child: IgnorePointer(
              child: Container(
                width: size * 0.5,
                height: size * 0.2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  color: topGloss,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [topGloss, Colors.transparent, bottomShade],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.notoSerifTc(
              color: textColor,
              fontSize: size * BoardVisualConfig.pieceFontSizeRatio,
              fontWeight: FontWeight.w700,
              height: 1,
              shadows: [
                Shadow(
                  color: Colors.black.withAlpha(isRed ? 128 : 153),
                  offset: Offset(piecePx(1), piecePx(1)),
                  blurRadius: piecePx(2),
                ),
                Shadow(
                  color:
                      (isRed
                              ? const Color(0x4DFFC8C8)
                              : const Color(0x33C8C8C8))
                          .withAlpha(isRed ? 77 : 51),
                  blurRadius: piecePx(isRed ? 8 : 6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRing extends StatelessWidget {
  final double size;
  final double spreadPx;
  final double glowPx;
  final Color color;
  final Color glowColor;

  const _StatusRing({
    required this.size,
    required this.spreadPx,
    required this.glowPx,
    required this.color,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final extra = _piecePx(spreadPx) * 2;

    return IgnorePointer(
      child: Container(
        width: size + extra,
        height: size + extra,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(color: color, width: _piecePx(spreadPx)),
          boxShadow: [
            BoxShadow(color: glowColor, blurRadius: _piecePx(glowPx)),
          ],
        ),
      ),
    );
  }

  double _piecePx(double px) {
    final basePieceSize =
        BoardVisualConfig.webCellSize * BoardVisualConfig.pieceSizeRatio;
    return px * (size / basePieceSize);
  }
}

class _OutlineRing extends StatelessWidget {
  final double size;
  final double insetPx;
  final double strokePx;
  final Color color;
  final double glowPx;
  final Color glowColor;
  final double? glowPxFar;
  final Color? glowColorFar;

  const _OutlineRing({
    required this.size,
    required this.insetPx,
    required this.strokePx,
    required this.color,
    required this.glowPx,
    required this.glowColor,
    this.glowPxFar,
    this.glowColorFar,
  });

  @override
  Widget build(BuildContext context) {
    final inset = _piecePx(insetPx);

    return IgnorePointer(
      child: Container(
        width: size + inset * 2,
        height: size + inset * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: _piecePx(strokePx)),
          boxShadow: [
            BoxShadow(color: glowColor, blurRadius: _piecePx(glowPx)),
            if (glowPxFar != null && glowColorFar != null)
              BoxShadow(color: glowColorFar!, blurRadius: _piecePx(glowPxFar!)),
          ],
        ),
      ),
    );
  }

  double _piecePx(double px) {
    final basePieceSize =
        BoardVisualConfig.webCellSize * BoardVisualConfig.pieceSizeRatio;
    return px * (size / basePieceSize);
  }
}
