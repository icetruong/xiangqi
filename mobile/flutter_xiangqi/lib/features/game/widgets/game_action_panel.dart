import 'package:flutter/material.dart';

import '../models/game_action_type.dart';
import 'game_action_button.dart';

class GameActionPanel extends StatelessWidget {
  static const double compactHeight = 38;

  final bool isGameFinished;
  final bool isBusy;
  final GameActionType? activeAction;
  final VoidCallback onResign;
  final VoidCallback onDraw;
  final VoidCallback onExit;

  const GameActionPanel({
    super.key,
    required this.isGameFinished,
    required this.isBusy,
    required this.activeAction,
    required this.onResign,
    required this.onDraw,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmitGameAction = !isBusy && !isGameFinished;
    final canExit = !isBusy;
    const buttonHeight = 38.0;
    const spacing = 6.0;

    return SizedBox(
      height: compactHeight,
      child: Row(
        children: [
          Expanded(
            child: GameActionButton(
              label: GameActionType.resign.label,
              seal: GameActionType.resign.seal,
              tone: GameActionType.resign.tone,
              height: buttonHeight,
              compact: true,
              dense: true,
              onPressed: canSubmitGameAction ? onResign : null,
              isLoading: activeAction == GameActionType.resign,
            ),
          ),
          const SizedBox(width: spacing),
          Expanded(
            child: GameActionButton(
              label: GameActionType.draw.label,
              seal: GameActionType.draw.seal,
              tone: GameActionType.draw.tone,
              height: buttonHeight,
              compact: true,
              dense: true,
              onPressed: canSubmitGameAction ? onDraw : null,
              isLoading: activeAction == GameActionType.draw,
            ),
          ),
          const SizedBox(width: spacing),
          Expanded(
            child: GameActionButton(
              label: GameActionType.exit.label,
              seal: GameActionType.exit.seal,
              tone: GameActionType.exit.tone,
              height: buttonHeight,
              compact: true,
              dense: true,
              onPressed: canExit ? onExit : null,
            ),
          ),
        ],
      ),
    );
  }
}
