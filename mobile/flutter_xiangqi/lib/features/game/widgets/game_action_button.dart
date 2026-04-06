import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../models/game_action_type.dart';

enum GameActionButtonTone { neutral, resign, draw, exit }

extension GameActionButtonToneForAction on GameActionType {
  GameActionButtonTone get tone => switch (this) {
    GameActionType.resign => GameActionButtonTone.resign,
    GameActionType.draw => GameActionButtonTone.draw,
    GameActionType.exit => GameActionButtonTone.exit,
  };
}

class GameActionButton extends StatelessWidget {
  final String label;
  final String seal;
  final String? subtitle;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final bool compact;
  final bool dense;
  final GameActionButtonTone tone;

  const GameActionButton({
    super.key,
    required this.label,
    required this.seal,
    required this.tone,
    this.subtitle,
    this.onPressed,
    this.isLoading = false,
    this.height = 48,
    this.compact = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(tone);
    final enabled = onPressed != null && !isLoading;
    final borderRadius = BorderRadius.circular(
      dense ? 11 : (compact ? 14 : 16),
    );
    final labelStyle = GoogleFonts.notoSerif(
      color: palette.labelColor,
      fontSize: dense ? 11.2 : (compact ? 13.2 : 15.5),
      fontWeight: FontWeight.w700,
      height: dense ? 1.0 : 1.1,
    );
    final showSubtitle = !dense && subtitle != null;
    final badgeSize = dense ? 18.0 : (compact ? 24.0 : 26.0);
    final badgeInset = dense ? 6.0 : (compact ? 8.0 : 10.0);
    final leftInset = dense ? 10.0 : (compact ? 12.0 : 14.0);
    final rightInset = badgeInset + badgeSize + (dense ? 8.0 : 12.0);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: palette.borderColor,
            width: dense ? 0.9 : 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.background,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.shadowColor,
              blurRadius: dense ? 7 : (compact ? 12 : 16),
              offset: Offset(0, dense ? 2.5 : 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: palette.innerBorderColor,
                      width: 0.7,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withAlpha(22),
                        Colors.transparent,
                        Colors.black.withAlpha(18),
                      ],
                      stops: const [0.0, 0.26, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: enabled ? onPressed : null,
                borderRadius: borderRadius,
                splashColor: palette.splashColor,
                highlightColor: Colors.transparent,
                child: SizedBox(
                  height: height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: leftInset,
                            end: rightInset,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: showSubtitle
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: labelStyle,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cinzel(
                                          color: palette.subtitleColor,
                                          fontSize: compact ? 8.4 : 9.4,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: compact ? 0.8 : 1.1,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      style: labelStyle,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        end: badgeInset,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: isLoading
                              ? SizedBox(
                                  width: dense ? 14 : (compact ? 18 : 20),
                                  height: dense ? 14 : (compact ? 18 : 20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: dense ? 1.8 : 2.1,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      palette.labelColor,
                                    ),
                                  ),
                                )
                              : _SealBadge(
                                  seal: seal,
                                  tone: tone,
                                  compact: compact,
                                  dense: dense,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _GameActionPalette _paletteFor(GameActionButtonTone tone) {
    return switch (tone) {
      GameActionButtonTone.neutral => const _GameActionPalette(
        background: [Color(0xFF4A2C19), Color(0xFF2B160C)],
        borderColor: Color(0xFF8E6A39),
        innerBorderColor: Color(0x44D2AD6C),
        labelColor: Color(0xFFF2E3C5),
        subtitleColor: Color(0xFFD0B480),
        shadowColor: Color(0x66000000),
        splashColor: Color(0x22D4AF37),
      ),
      GameActionButtonTone.resign => const _GameActionPalette(
        background: [Color(0xFF7A1C10), Color(0xFF5A1209)],
        borderColor: Color(0xFFA03020),
        innerBorderColor: Color(0x45E07E72),
        labelColor: Color(0xFFF5E0C0),
        subtitleColor: Color(0xFFE2B39F),
        shadowColor: Color(0x6B1D0504),
        splashColor: Color(0x22F39A7E),
      ),
      GameActionButtonTone.draw => const _GameActionPalette(
        background: [Color(0xFF6B4E0A), Color(0xFF4A3407)],
        borderColor: Color(0xFF9A7220),
        innerBorderColor: Color(0x45F2D279),
        labelColor: Color(0xFFFFE9A0),
        subtitleColor: Color(0xFFE5D08C),
        shadowColor: Color(0x66402202),
        splashColor: Color(0x22FFE9A0),
      ),
      GameActionButtonTone.exit => const _GameActionPalette(
        background: [Color(0xFF1A2E3E), Color(0xFF0E1E2A)],
        borderColor: Color(0xFF2E5070),
        innerBorderColor: Color(0x457AB4D4),
        labelColor: Color(0xFFD5E7F8),
        subtitleColor: Color(0xFFA8C8DF),
        shadowColor: Color(0x6610161F),
        splashColor: Color(0x227DBBE0),
      ),
    };
  }
}

class _SealBadge extends StatelessWidget {
  final String seal;
  final GameActionButtonTone tone;
  final bool compact;
  final bool dense;

  const _SealBadge({
    required this.seal,
    required this.tone,
    required this.compact,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = switch (tone) {
      GameActionButtonTone.neutral => const BoxDecoration(
        color: Color(0xFF6A4725),
        borderRadius: BorderRadius.all(Radius.circular(6)),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFF9A753B), width: 0.9),
        ),
      ),
      GameActionButtonTone.resign => const BoxDecoration(
        color: Color(0xFF8B1A1A),
        borderRadius: BorderRadius.all(Radius.circular(6)),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFF5E0E0D), width: 0.9),
        ),
      ),
      GameActionButtonTone.draw => const BoxDecoration(
        color: Color(0xFF7A5A10),
        borderRadius: BorderRadius.all(Radius.circular(6)),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFF4A3408), width: 0.9),
        ),
      ),
      GameActionButtonTone.exit => const BoxDecoration(
        color: Color(0xFF1E3E54),
        borderRadius: BorderRadius.all(Radius.circular(6)),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFF173244), width: 0.9),
        ),
      ),
    };

    return Container(
      width: dense ? 18 : (compact ? 24 : 26),
      height: dense ? 18 : (compact ? 24 : 26),
      decoration: decoration.copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(70),
            blurRadius: dense ? 3 : (compact ? 5 : 6),
            offset: Offset(0, dense ? 1 : 2),
          ),
          BoxShadow(
            color: Colors.white.withAlpha(16),
            blurRadius: 0,
            spreadRadius: 0.1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          seal,
          style: GoogleFonts.notoSerifTc(
            color: XiangqiColors.parchment,
            fontSize: dense ? 9.6 : (compact ? 12.5 : 13.5),
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _GameActionPalette {
  final List<Color> background;
  final Color borderColor;
  final Color innerBorderColor;
  final Color labelColor;
  final Color subtitleColor;
  final Color shadowColor;
  final Color splashColor;

  const _GameActionPalette({
    required this.background,
    required this.borderColor,
    required this.innerBorderColor,
    required this.labelColor,
    required this.subtitleColor,
    required this.shadowColor,
    required this.splashColor,
  });
}
