import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/piece_mapper.dart';

/// Renders a single Xiangqi piece.
///
/// Responsibilities:
///   • Draw the piece as a circular token with a Chinese character label.
///   • Optionally use an image asset when [PieceMapper.assetsAvailable] is true
///     and the asset exists (falls back to the text label on error).
///   • Show a highlight ring when [isSelected] is true.
///
/// Does NOT know about board coordinates.  Positioning is the caller's job.
class PieceWidget extends StatelessWidget {
  /// Piece colour: 'r' or 'b'.
  final String color;

  /// Piece type code: 'K', 'A', 'E', 'H', 'R', 'C', or 'P'.
  final String type;

  /// Diameter of the piece circle in logical pixels.
  final double size;

  /// Whether to display the selection highlight ring.
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
    Widget piece;
    if (PieceMapper.assetsAvailable) {
      final path = PieceMapper.assetPath(color, type);
      if (path != null) {
        piece = _ImagePiece(
          color: color,
          type: type,
          size: size,
          assetPath: path,
        );
      } else {
        piece = _TextPiece(color: color, type: type, size: size);
      }
    } else {
      piece = _TextPiece(color: color, type: type, size: size);
    }

    if (!isSelected) return piece;

    // Selection overlay: bright cyan ring + subtle glow.
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow ring (slightly larger than the piece).
        Container(
          width: size + size * 0.28,
          height: size + size * 0.28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF00E5FF), // cyan accent
              width: size * 0.07,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withAlpha(120),
                blurRadius: size * 0.35,
                spreadRadius: size * 0.04,
              ),
            ],
          ),
        ),
        piece,
      ],
    );
  }
}

// ── Text fallback ─────────────────────────────────────────────────────────

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

    final bgColor = isRed ? const Color(0xFFC0392B) : const Color(0xFF2F2F2F);
    final textColor = isRed ? Colors.white : const Color(0xFFDDDDDD);
    final borderColor =
        isRed ? const Color(0xFF6B1010) : const Color(0xFF111111);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: borderColor, width: size * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: size * 0.12,
            offset: Offset(size * 0.04, size * 0.06),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}

// ── Image variant ─────────────────────────────────────────────────────────

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
    final textColor =
        color == 'r' ? Colors.white : const Color(0xFFDDDDDD);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            assetPath,
            width: size,
            height: size,
          ),
          // We apply a slight downward offset for the text to perfectly center it visually
          // on the 3D-looking token (which has a shadow/bevel pushing it up).
          Transform.translate(
            offset: Offset(0, -size * 0.05),
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: size * 0.52,
                fontFamily: 'serif',
                fontWeight: FontWeight.bold,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(120),
                    offset: Offset(1, 1),
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
