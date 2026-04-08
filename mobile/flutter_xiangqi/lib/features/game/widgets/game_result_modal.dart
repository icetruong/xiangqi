import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/framed_panel.dart';
import '../../../shared/widgets/ornament_divider.dart';
import '../models/game_result_view_model.dart';
import 'result_action_button.dart';

enum GameResultModalAction { stay, goHome, playAgain }

class GameResultModalResult {
  final GameResultModalAction action;
  final String? nextGameId;

  const GameResultModalResult._({required this.action, this.nextGameId});

  const GameResultModalResult.stay()
    : this._(action: GameResultModalAction.stay);

  const GameResultModalResult.goHome()
    : this._(action: GameResultModalAction.goHome);

  const GameResultModalResult.playAgain(String gameId)
    : this._(action: GameResultModalAction.playAgain, nextGameId: gameId);
}

class GameResultModal extends StatefulWidget {
  final GameResultViewModel viewModel;
  final Future<String> Function() onPlayAgain;

  const GameResultModal({
    super.key,
    required this.viewModel,
    required this.onPlayAgain,
  });

  static Future<GameResultModalResult?> show(
    BuildContext context, {
    required GameResultViewModel viewModel,
    required Future<String> Function() onPlayAgain,
  }) {
    return showGeneralDialog<GameResultModalResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Kết quả ván đấu',
      barrierColor: const Color(0xD6150905),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return GameResultModal(viewModel: viewModel, onPlayAgain: onPlayAgain);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final scale = Tween<double>(begin: 0.94, end: 1).animate(fade);

        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  @override
  State<GameResultModal> createState() => _GameResultModalState();
}

class _GameResultModalState extends State<GameResultModal> {
  bool _isStartingNewGame = false;
  String? _actionError;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.viewModel.outcome);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.8, sigmaY: 2.8),
                child: const ColoredBox(color: Color(0x33000000)),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 22,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.glowColor,
                                  blurRadius: 46,
                                  spreadRadius: -6,
                                ),
                                BoxShadow(
                                  color: Colors.black.withAlpha(180),
                                  blurRadius: 38,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: palette.outerBorder,
                            width: 1.05,
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF4A2414),
                              Color(0xFF29150B),
                              Color(0xFF180C07),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          child: FramedPanel(
                            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: palette.badgeBorder,
                                        width: 1.2,
                                      ),
                                      gradient: RadialGradient(
                                        center: const Alignment(-0.18, -0.24),
                                        radius: 0.92,
                                        colors: [
                                          palette.badgeHighlight,
                                          palette.badgeFill,
                                          palette.badgeDeep,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: palette.badgeShadow,
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        widget.viewModel.hanzi,
                                        style: GoogleFonts.notoSerifTc(
                                          color: const Color(0xFFF8ECD4),
                                          fontSize: 44,
                                          fontWeight: FontWeight.w700,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.viewModel.eyebrow,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cinzel(
                                    color: XiangqiColors.textMuted,
                                    fontSize: 10.4,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.viewModel.title,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.notoSerif(
                                    color: const Color(0xFF43210D),
                                    fontSize: 27,
                                    fontWeight: FontWeight.w700,
                                    height: 1.06,
                                  ),
                                ),
                                const OrnamentDivider(verticalPadding: 18),
                                Text(
                                  widget.viewModel.subtitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.notoSerif(
                                    color: const Color(0xFF4C2A13),
                                    fontSize: 15.2,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: palette.reasonBorder,
                                        width: 0.9,
                                      ),
                                      gradient: LinearGradient(
                                        colors: [
                                          palette.reasonFill,
                                          palette.reasonFill.withAlpha(
                                            (0.8 * 255).round(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      widget.viewModel.reasonLabel,
                                      style: GoogleFonts.cinzel(
                                        color: palette.reasonText,
                                        fontSize: 9.4,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.9,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  widget.viewModel.description,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.notoSerif(
                                    color: const Color(0xFF5C3A20),
                                    fontSize: 13.1,
                                    fontWeight: FontWeight.w600,
                                    height: 1.55,
                                  ),
                                ),
                                if (_actionError != null) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: const Color(0xFFF7E7DB),
                                      border: Border.all(
                                        color: const Color(0xFFD08A6F),
                                        width: 0.9,
                                      ),
                                    ),
                                    child: Text(
                                      _actionError!,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.notoSerif(
                                        color: const Color(0xFF7A2313),
                                        fontSize: 12.2,
                                        fontWeight: FontWeight.w600,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isCompact =
                                        constraints.maxWidth < 320;
                                    if (isCompact) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          ResultActionButton(
                                            label: 'Chơi lại',
                                            seal: '再',
                                            tone:
                                                ResultActionButtonTone.primary,
                                            subtitle: 'Cùng phe, cùng độ khó',
                                            isLoading: _isStartingNewGame,
                                            onPressed: _isStartingNewGame
                                                ? null
                                                : _handlePlayAgain,
                                          ),
                                          const SizedBox(height: 10),
                                          ResultActionButton(
                                            label: 'Về trang chính',
                                            seal: '歸',
                                            tone: ResultActionButtonTone
                                                .secondary,
                                            subtitle: 'Rời bàn cờ hiện tại',
                                            onPressed: _handleGoHome,
                                          ),
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: [
                                        Expanded(
                                          child: ResultActionButton(
                                            label: 'Chơi lại',
                                            seal: '再',
                                            tone:
                                                ResultActionButtonTone.primary,
                                            subtitle: 'Cùng phe, cùng độ khó',
                                            isLoading: _isStartingNewGame,
                                            onPressed: _isStartingNewGame
                                                ? null
                                                : _handlePlayAgain,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ResultActionButton(
                                            label: 'Về trang chính',
                                            seal: '歸',
                                            tone: ResultActionButtonTone
                                                .secondary,
                                            subtitle: 'Rời bàn cờ hiện tại',
                                            onPressed: _handleGoHome,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                ResultActionButton(
                                  label: 'Xem bàn cờ',
                                  seal: '觀',
                                  tone: ResultActionButtonTone.tertiary,
                                  subtitle: 'Đóng modal và giữ thế cờ',
                                  onPressed: _handleStay,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 18,
                        right: 22,
                        child: _ResultStamp(
                          text: widget.viewModel.seal,
                          palette: palette,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePlayAgain() async {
    setState(() {
      _isStartingNewGame = true;
      _actionError = null;
    });

    try {
      final nextGameId = await widget.onPlayAgain();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(GameResultModalResult.playAgain(nextGameId));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _actionError = 'Không thể tạo ván mới ngay lúc này. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStartingNewGame = false;
        });
      }
    }
  }

  void _handleGoHome() {
    Navigator.of(context).pop(const GameResultModalResult.goHome());
  }

  void _handleStay() {
    Navigator.of(context).pop(const GameResultModalResult.stay());
  }

  _ResultModalPalette _paletteFor(GameResultOutcome outcome) {
    return switch (outcome) {
      GameResultOutcome.victory => const _ResultModalPalette(
        glowColor: Color(0x66C99543),
        outerBorder: Color(0xB7965D20),
        badgeFill: Color(0xFF983016),
        badgeHighlight: Color(0xFFD66C30),
        badgeDeep: Color(0xFF64170A),
        badgeBorder: Color(0xFFD2B177),
        badgeShadow: Color(0x77371208),
        reasonFill: Color(0x22B44922),
        reasonBorder: Color(0xAA9F6E1E),
        reasonText: Color(0xFF7C5315),
        stampFill: Color(0xFF972018),
        stampBorder: Color(0xFF6B140F),
        stampText: Color(0xFFF9E9D3),
      ),
      GameResultOutcome.defeat => const _ResultModalPalette(
        glowColor: Color(0x55A53122),
        outerBorder: Color(0xB77B401F),
        badgeFill: Color(0xFF6D1A12),
        badgeHighlight: Color(0xFFB13A28),
        badgeDeep: Color(0xFF43100C),
        badgeBorder: Color(0xFFC79A73),
        badgeShadow: Color(0x6E1C0806),
        reasonFill: Color(0x22B44522),
        reasonBorder: Color(0xAA924E33),
        reasonText: Color(0xFF7A301D),
        stampFill: Color(0xFF7B1814),
        stampBorder: Color(0xFF54100E),
        stampText: Color(0xFFF7E3D8),
      ),
      GameResultOutcome.draw => const _ResultModalPalette(
        glowColor: Color(0x55AF8A2A),
        outerBorder: Color(0xB78D6B28),
        badgeFill: Color(0xFF8B6312),
        badgeHighlight: Color(0xFFC99027),
        badgeDeep: Color(0xFF5C3D0B),
        badgeBorder: Color(0xFFD8BA74),
        badgeShadow: Color(0x66341F03),
        reasonFill: Color(0x22B38B2A),
        reasonBorder: Color(0xAAA67B22),
        reasonText: Color(0xFF6A4C0E),
        stampFill: Color(0xFF876019),
        stampBorder: Color(0xFF5C420E),
        stampText: Color(0xFFF8E9C8),
      ),
    };
  }
}

class _ResultStamp extends StatelessWidget {
  final String text;
  final _ResultModalPalette palette;

  const _ResultStamp({required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: palette.stampFill.withAlpha((0.9 * 255).round()),
          border: Border.all(color: palette.stampBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(72),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.cinzel(
            color: palette.stampText,
            fontSize: 9.1,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _ResultModalPalette {
  final Color glowColor;
  final Color outerBorder;
  final Color badgeFill;
  final Color badgeHighlight;
  final Color badgeDeep;
  final Color badgeBorder;
  final Color badgeShadow;
  final Color reasonFill;
  final Color reasonBorder;
  final Color reasonText;
  final Color stampFill;
  final Color stampBorder;
  final Color stampText;

  const _ResultModalPalette({
    required this.glowColor,
    required this.outerBorder,
    required this.badgeFill,
    required this.badgeHighlight,
    required this.badgeDeep,
    required this.badgeBorder,
    required this.badgeShadow,
    required this.reasonFill,
    required this.reasonBorder,
    required this.reasonText,
    required this.stampFill,
    required this.stampBorder,
    required this.stampText,
  });
}
