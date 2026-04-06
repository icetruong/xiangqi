import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../data/models/game_state_model.dart';
import 'side_status_panel.dart';
import 'versus_center_badge.dart';

/// Compact mobile adaptation of the web side identity cards.
class VersusHeader extends StatelessWidget {
  static const double compactHeight = 92;

  final GameStateModel game;

  const VersusHeader({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final playerSide = _normalizeSide(game.playerSide) ?? 'r';
    final opponentSide =
        _normalizeSide(game.aiSide) ?? (playerSide == 'r' ? 'b' : 'r');
    final emphasizedSide = _emphasizedSide(
      status: game.status,
      winner: game.winner,
      currentTurn: game.currentTurn,
      playerSide: playerSide,
      opponentSide: opponentSide,
    );
    final statusCopy = _statusCopy(
      status: game.status,
      winner: game.winner,
      endReason: game.endReason,
      currentTurn: game.currentTurn,
      playerSide: playerSide,
      isAiThinking: game.isAiThinking,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: XiangqiColors.goldDark.withAlpha(112),
          width: 0.85,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xD934160A), Color(0xE61B0C06)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(96),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SideStatusPanel(
                        label: 'Bạn',
                        side: playerSide,
                        isHighlighted: emphasizedSide == playerSide,
                        isDimmed:
                            emphasizedSide != null &&
                            emphasizedSide != playerSide,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const VersusCenterBadge(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SideStatusPanel(
                        label: 'AI',
                        side: opponentSide,
                        isHighlighted: emphasizedSide == opponentSide,
                        isDimmed:
                            emphasizedSide != null &&
                            emphasizedSide != opponentSide,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            _StatusStrip(copy: statusCopy),
          ],
        ),
      ),
    );
  }

  String? _normalizeSide(String? side) {
    if (side == 'r' || side == 'b') {
      return side;
    }
    return null;
  }

  String? _emphasizedSide({
    required String status,
    required String? winner,
    required String currentTurn,
    required String playerSide,
    required String opponentSide,
  }) {
    if (status == 'ongoing') {
      return currentTurn == playerSide ? playerSide : opponentSide;
    }
    if (status == 'finished') {
      if (winner == playerSide || winner == opponentSide) {
        return winner;
      }
      return null;
    }
    return null;
  }

  _StatusCopy _statusCopy({
    required String status,
    required String? winner,
    required String? endReason,
    required String currentTurn,
    required String playerSide,
    required bool isAiThinking,
  }) {
    if (status == 'ongoing') {
      return _StatusCopy(
        icon: isAiThinking
            ? Icons.psychology_alt_rounded
            : Icons.timelapse_rounded,
        text: isAiThinking
            ? 'AI đang tính nước'
            : currentTurn == playerSide
            ? 'Đến lượt bạn'
            : 'Đến lượt AI',
      );
    }

    if (status == 'finished') {
      final winnerText = switch (winner) {
        'draw' => 'Ván cờ hòa',
        final value when value == playerSide => 'Bạn chiến thắng',
        'r' || 'b' => 'AI chiến thắng',
        _ => 'Ván đấu đã kết thúc',
      };
      final reasonText = _reasonText(endReason);
      return _StatusCopy(
        icon: winner == 'draw' ? Icons.balance_rounded : Icons.flag_rounded,
        text: reasonText == null ? winnerText : '$winnerText • $reasonText',
      );
    }

    return _StatusCopy(
      icon: Icons.info_outline_rounded,
      text: 'Trạng thái: $status',
    );
  }

  String? _reasonText(String? reason) {
    switch (reason) {
      case 'checkmate':
        return 'Chiếu bí';
      case 'stalemate':
        return 'Hết nước đi';
      case 'resign':
        return 'Nhận thua';
      case 'draw_agreement':
        return 'Hòa thỏa thuận';
      default:
        return null;
    }
  }
}

class _StatusCopy {
  final IconData icon;
  final String text;

  const _StatusCopy({required this.icon, required this.text});
}

class _StatusStrip extends StatelessWidget {
  final _StatusCopy copy;

  const _StatusStrip({required this.copy});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: XiangqiColors.goldDark.withAlpha(72),
          width: 0.7,
        ),
        color: Colors.black.withAlpha(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(42),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              copy.icon,
              size: 12,
              color: XiangqiColors.goldLight.withAlpha(214),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                copy.text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSerif(
                  color: XiangqiColors.parchment.withAlpha(232),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
