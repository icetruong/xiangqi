import 'package:flutter/material.dart';
import '../../../core/utils/captured_pieces_helper.dart';
import '../../../core/utils/piece_mapper.dart';

/// Compact display of pieces captured by both sides.
///
/// Renders two slim rows (one per side) above/below the board.
/// Purely presentational: no game logic here.
class CapturedPiecesPanel extends StatelessWidget {
  final CapturedPieces captured;

  const CapturedPiecesPanel({super.key, required this.captured});

  @override
  Widget build(BuildContext context) {
    if (captured.isEmpty) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFF2A1000), // dark warm brown matching the game screen bg
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (captured.capturedByRed.isNotEmpty)
            _CapturedRow(
              label: '🔴',
              pieces: captured.capturedByRed,
              labelColor: const Color(0xFFFFB3B3),
            ),
          if (captured.capturedByBlack.isNotEmpty)
            _CapturedRow(
              label: '⚫',
              pieces: captured.capturedByBlack,
              labelColor: const Color(0xFFCCCCCC),
            ),
        ],
      ),
    );
  }
}

// ── Single captured-row ──────────────────────────────────────────────────────

class _CapturedRow extends StatelessWidget {
  final String label;
  final List<String> pieces;
  final Color labelColor;

  const _CapturedRow({
    required this.label,
    required this.pieces,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontSize: 11),
          ),
          Expanded(
            child: Wrap(
              spacing: 3,
              runSpacing: 2,
              children: pieces.map((code) => _PieceBadge(code: code)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Piece badge ──────────────────────────────────────────────────────────────

class _PieceBadge extends StatelessWidget {
  final String code; // e.g. 'bP', 'rR'

  const _PieceBadge({required this.code});

  @override
  Widget build(BuildContext context) {
    if (code.length != 2) return const SizedBox.shrink();

    final color = code[0];
    final type = code[1].toUpperCase();
    final isRed = color == 'r';

    final bg = isRed ? const Color(0xFF5A1A1A) : const Color(0xFF2A2A2A);
    final fg = isRed ? const Color(0xFFFFB3B3) : const Color(0xFFCCCCCC);
    final border = isRed ? const Color(0xFF8B2020) : const Color(0xFF444444);
    final label = PieceMapper.chineseLabel(color, type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}
