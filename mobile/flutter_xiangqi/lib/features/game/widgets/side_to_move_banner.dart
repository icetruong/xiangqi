import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../data/models/game_state_model.dart';

/// Displays whose turn it is, the current game status, and whether the AI
/// is currently computing its reply.
class SideToMoveBanner extends StatelessWidget {
  final GameStateModel game;

  const SideToMoveBanner({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF2A1000), // slightly lighter than darkBrown
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _SideChip(currentTurn: game.currentTurn),
          _StatusChip(status: game.status, winner: game.winner),
          if (game.isAiThinking) const _AiThinkingChip(),
        ],
      ),
    );
  }
}

// ── Private sub-widgets ─────────────────────────────────────────────────────

class _SideChip extends StatelessWidget {
  final String currentTurn;

  const _SideChip({required this.currentTurn});

  @override
  Widget build(BuildContext context) {
    final isRed = currentTurn == 'r';
    final label = isRed ? '🔴 Red to move' : '⚫ Black to move';
    final bg = isRed
        ? const Color(0xFF6B1A1A) // dark red tint
        : const Color(0xFF3A3A3A); // dark grey
    final fg = isRed ? const Color(0xFFFFB3B3) : const Color(0xFFCCCCCC);

    return Chip(
      label: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
      backgroundColor: bg,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final String? winner;

  const _StatusChip({required this.status, this.winner});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color fg;

    switch (status) {
      case 'finished':
        final w = winner;
        if (w == 'draw') {
          label = '🤝 Draw'; bg = const Color(0xFF2A3A4A); fg = const Color(0xFF90CAF9);
        } else if (w == 'r') {
          label = '🏆 Red wins'; bg = const Color(0xFF6B1A1A); fg = const Color(0xFFFFB3B3);
        } else if (w == 'b') {
          label = '🏆 Black wins'; bg = const Color(0xFF2A2A2A); fg = const Color(0xFFCCCCCC);
        } else {
          label = 'Finished'; bg = const Color(0xFF333333); fg = XiangqiColors.parchment;
        }
      case 'ongoing':
        label = '▶ Ongoing'; bg = const Color(0xFF1A3A1A); fg = const Color(0xFF81C784);
      default:
        label = status; bg = const Color(0xFF333333); fg = XiangqiColors.parchment;
    }

    return Chip(
      label: Text(label, style: TextStyle(fontSize: 12, color: fg)),
      backgroundColor: bg,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _AiThinkingChip extends StatelessWidget {
  const _AiThinkingChip();

  @override
  Widget build(BuildContext context) {
    return const Chip(
      avatar: SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(XiangqiColors.goldLight),
        ),
      ),
      label: Text('AI thinking…',
          style: TextStyle(fontSize: 12, color: Color(0xFFFFE082))),
      backgroundColor: Color(0xFF3A2E00),
      padding: EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
