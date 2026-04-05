import 'package:flutter/material.dart';
import '../../../data/models/move_model.dart';
import '../../../core/utils/piece_mapper.dart';

/// Collapsible move history panel.
///
/// Shows a compact, scrollable list of all moves played so far.
/// Each row displays: ply · side icon · piece · from→to · captured (if any).
///
/// Designed to sit directly below the board in the game layout column.
/// When collapsed it occupies only the header row height (~40 px).
class MoveHistoryPanel extends StatefulWidget {
  final List<MoveModel> moveHistory;

  const MoveHistoryPanel({super.key, required this.moveHistory});

  @override
  State<MoveHistoryPanel> createState() => _MoveHistoryPanelState();
}

class _MoveHistoryPanelState extends State<MoveHistoryPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final moves = widget.moveHistory;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header row (always visible) ───────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.history, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Move History (${moves.length})',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        // ── Collapsible list ──────────────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _expanded
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: moves.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'No moves yet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: moves.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, indent: 12, endIndent: 12),
                          itemBuilder: (context, i) {
                            // Reverse so newest move appears at the top.
                            final move = moves[moves.length - 1 - i];
                            return _MoveRow(move: move);
                          },
                        ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Single move row ──────────────────────────────────────────────────────────

class _MoveRow extends StatelessWidget {
  final MoveModel move;

  const _MoveRow({required this.move});

  @override
  Widget build(BuildContext context) {
    final isRed = (move.side ?? '') == 'r';
    final sideColor = isRed ? const Color(0xFFC62828) : Colors.black87;
    final sideLabel = isRed ? '🔴' : '⚫';

    // Piece label (e.g. '馬') — use piece code if available.
    final pieceCode = move.piece; // e.g. 'rH'
    String pieceLabel = '';
    if (pieceCode != null && pieceCode.length == 2) {
      pieceLabel = PieceMapper.chineseLabel(
        pieceCode[0],
        pieceCode[1].toUpperCase(),
      );
    }

    final fromStr = '(${move.from[0]},${move.from[1]})';
    final toStr = '(${move.to[0]},${move.to[1]})';

    final cap = move.captured;
    String capturedLabel = '';
    if (cap != null && cap.length == 2) {
      capturedLabel =
          ' ×${PieceMapper.chineseLabel(cap[0], cap[1].toUpperCase())}';
    }

    final plyLabel = move.ply != null ? '${move.ply}.' : '—.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          // Ply number
          SizedBox(
            width: 28,
            child: Text(
              plyLabel,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          // Side icon
          Text(sideLabel, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          // Piece + move
          Expanded(
            child: Text(
              '$pieceLabel $fromStr→$toStr$capturedLabel',
              style: TextStyle(
                fontSize: 12,
                color: sideColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
