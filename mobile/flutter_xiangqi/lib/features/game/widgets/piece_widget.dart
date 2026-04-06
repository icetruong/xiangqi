import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme.dart';
import '../../../core/utils/piece_mapper.dart';

/// Renders a single Xiangqi piece.
class PieceWidget extends StatelessWidget {
  final String color;
  final String type;
  final double size;
  final bool isSelected;

  const PieceWidget({
    super.key,
    required this.color,
    required this.type,
    required this.size,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = PieceMapper.assetsAvailable
        ? PieceMapper.assetPath(color, type)
        : null;

    final piece = assetPath == null
        ? _TextPiece(color: color, type: type, size: size)
        : _ImagePiece(
            color: color,
            type: type,
            size: size,
            assetPath: assetPath,
          );

    if (!isSelected) return piece;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IgnorePointer(
          child: Container(
            width: size + size * 0.36,
            height: size + size * 0.36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: XiangqiColors.highlightGold,
                width: size * 0.08,
              ),
              boxShadow: [
                BoxShadow(
                  color: XiangqiColors.highlightGold.withAlpha(110),
                  blurRadius: size * 0.28,
                  spreadRadius: size * 0.02,
                ),
              ],
            ),
          ),
        ),
        piece,
      ],
    );
  }
}

class _TextPiece extends StatelessWidget {
  final String color;
  final String type;
  final double size;

  const _TextPiece({
    required this.color,
    required this.type,
    required this.size,
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

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.24, -0.36),
          radius: 0.78,
          colors: [highlightColor, innerColor, outerColor],
          stops: const [0.0, 0.42, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: size * 0.17,
            offset: Offset(size * 0.05, size * 0.08),
          ),
          BoxShadow(color: borderColor, spreadRadius: size * 0.07),
          BoxShadow(color: XiangqiColors.pieceRim, spreadRadius: size * 0.055),
          BoxShadow(color: outerColor, spreadRadius: size * 0.03),
        ],
      ),
      child: Transform.translate(
        offset: Offset(0, -size * 0.04),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.56,
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
            height: 1,
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(128),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePiece extends StatelessWidget {
  final String color;
  final String type;
  final double size;
  final String assetPath;

  const _ImagePiece({
    required this.color,
    required this.type,
    required this.size,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    final label = PieceMapper.chineseLabel(color, type);
    final textColor = color == 'r' ? Colors.white : const Color(0xFFE8E0D0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          SvgPicture.asset(assetPath, width: size, height: size),
          Transform.translate(
            offset: Offset(0, -size * 0.045),
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: size * 0.56,
                fontFamily: 'serif',
                fontWeight: FontWeight.bold,
                height: 1,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(138),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
