import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../data/models/game_state_model.dart';
import '../../../shared/widgets/themed_confirm_dialog.dart';
import 'game_action_button.dart';

class GameResultDialog extends StatelessWidget {
  final GameStateModel game;
  final VoidCallback onLeave;

  const GameResultDialog({
    super.key,
    required this.game,
    required this.onLeave,
  });

  static Future<void> show(
    BuildContext context, {
    required GameStateModel game,
    required VoidCallback onLeave,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: const Color(0xD1140804),
      builder: (_) => GameResultDialog(game: game, onLeave: onLeave),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerSide = game.playerSide ?? 'r';
    final tone = _toneFor(game.winner, playerSide);

    return ThemedDialogFrame(
      eyebrow: 'Match Result',
      seal: _sealFor(game.winner, playerSide),
      title: _titleFor(game.winner, playerSide),
      tone: tone,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _summaryFor(game.winner, playerSide, game.endReason),
            style: GoogleFonts.notoSerif(
              color: XiangqiColors.lacquerPanelText.withAlpha(238),
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _bodyFor(game.winner, playerSide),
            style: GoogleFonts.notoSerif(
              color: XiangqiColors.lacquerPanelMutedText,
              fontSize: 12.4,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GameActionButton(
                  label: 'Ở lại',
                  seal: '守',
                  tone: GameActionButtonTone.neutral,
                  compact: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameActionButton(
                  label: 'Về sảnh',
                  seal: '退',
                  tone: GameActionButtonTone.exit,
                  compact: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onLeave();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  GameActionButtonTone _toneFor(String? winner, String playerSide) {
    if (winner == 'draw') {
      return GameActionButtonTone.draw;
    }
    if (winner == playerSide) {
      return GameActionButtonTone.exit;
    }
    return GameActionButtonTone.resign;
  }

  String _sealFor(String? winner, String playerSide) {
    if (winner == 'draw') {
      return '和';
    }
    if (winner == playerSide) {
      return '勝';
    }
    return '敗';
  }

  String _titleFor(String? winner, String playerSide) {
    if (winner == 'draw') {
      return 'Ván cờ kết thúc hòa';
    }
    if (winner == playerSide) {
      return 'Bạn chiến thắng';
    }
    return 'Bạn đã thất bại';
  }

  String _summaryFor(String? winner, String playerSide, String? endReason) {
    final reasonText = switch (endReason) {
      'checkmate' => 'Chiếu bí',
      'stalemate' => 'Hết nước đi',
      'resign' => 'Nhận thua',
      'draw_agreement' => 'Hòa thỏa thuận',
      _ => 'Kết thúc ván cờ',
    };

    if (winner == 'draw') {
      return 'Hai bên khép lại trận đấu trong hòa cục. Lý do: $reasonText.';
    }
    if (winner == playerSide) {
      return 'Bạn đã áp đảo thế trận và giành chiến thắng. Lý do: $reasonText.';
    }
    return 'Thế cờ đã khép lại nghiêng về AI. Lý do: $reasonText.';
  }

  String _bodyFor(String? winner, String playerSide) {
    if (winner == 'draw') {
      return 'Bạn có thể ở lại xem lại bàn cờ hoặc quay về sảnh để bắt đầu một ván mới.';
    }
    if (winner == playerSide) {
      return 'Bạn có thể nán lại để xem thế cờ cuối hoặc trở về sảnh để mở trận tiếp theo.';
    }
    return 'Bạn có thể xem lại cục diện cuối cùng hoặc quay về sảnh để tái đấu ngay.';
  }
}
