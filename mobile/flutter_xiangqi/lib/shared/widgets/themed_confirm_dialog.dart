import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../features/game/models/game_action_type.dart';
import '../../features/game/widgets/game_action_button.dart';

class ThemedDialogFrame extends StatelessWidget {
  final String eyebrow;
  final String seal;
  final String title;
  final GameActionButtonTone tone;
  final Widget child;

  const ThemedDialogFrame({
    super.key,
    required this.eyebrow,
    required this.seal,
    required this.title,
    required this.tone,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = switch (tone) {
      GameActionButtonTone.resign => const Color(0xFFE8A197),
      GameActionButtonTone.draw => const Color(0xFFFFE4A1),
      GameActionButtonTone.exit => const Color(0xFFB8DAF2),
      GameActionButtonTone.neutral => XiangqiColors.parchment,
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: XiangqiColors.goldDark.withAlpha(164),
                width: 1,
              ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3D1F11),
                  XiangqiColors.lacquerPanelMid,
                  XiangqiColors.lacquerPanelBottom,
                ],
                stops: [0.0, 0.58, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(155),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: XiangqiColors.goldLight.withAlpha(44),
                          width: 0.8,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withAlpha(18),
                            Colors.transparent,
                            Colors.black.withAlpha(18),
                          ],
                          stops: const [0.0, 0.24, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _DialogSeal(seal: seal, tone: tone),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eyebrow,
                                  style: GoogleFonts.cinzel(
                                    color: XiangqiColors.lacquerPanelMutedText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  style: GoogleFonts.notoSerif(
                                    color: accentColor,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    height: 1.16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              XiangqiColors.goldLight.withAlpha(126),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      child,
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 14,
            right: 18,
            child: Text(
              '◈',
              style: TextStyle(
                color: XiangqiColors.goldLight.withAlpha(70),
                fontSize: 12,
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            left: 18,
            child: Text(
              '◈',
              style: TextStyle(
                color: XiangqiColors.goldLight.withAlpha(70),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ThemedConfirmDialog extends StatelessWidget {
  final GameActionType action;

  const ThemedConfirmDialog({super.key, required this.action});

  static Future<bool> show(
    BuildContext context, {
    required GameActionType action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xC9110502),
      builder: (context) => ThemedConfirmDialog(action: action),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ThemedDialogFrame(
      eyebrow: action.eyebrow,
      seal: action.seal,
      title: action.confirmTitle,
      tone: action.tone,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            action.confirmBody,
            style: GoogleFonts.notoSerif(
              color: XiangqiColors.lacquerPanelText.withAlpha(236),
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            action.confirmDetail,
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
                  label: action.cancelLabel,
                  seal: '止',
                  tone: GameActionButtonTone.neutral,
                  compact: true,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameActionButton(
                  label: action.confirmLabel,
                  seal: action.seal,
                  tone: action.tone,
                  compact: true,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogSeal extends StatelessWidget {
  final String seal;
  final GameActionButtonTone tone;

  const _DialogSeal({required this.seal, required this.tone});

  @override
  Widget build(BuildContext context) {
    final accent = switch (tone) {
      GameActionButtonTone.resign => const [
        Color(0xFF8B1A1A),
        Color(0xFF5E0E0D),
      ],
      GameActionButtonTone.draw => const [Color(0xFF7A5A10), Color(0xFF4A3408)],
      GameActionButtonTone.exit => const [Color(0xFF1E3E54), Color(0xFF173244)],
      GameActionButtonTone.neutral => const [
        Color(0xFF7A5A2A),
        Color(0xFF573A19),
      ],
    };

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: XiangqiColors.goldDark.withAlpha(170),
          width: 0.95,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: accent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(112),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          seal,
          style: GoogleFonts.notoSerifTc(
            color: XiangqiColors.parchment,
            fontSize: 27,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
