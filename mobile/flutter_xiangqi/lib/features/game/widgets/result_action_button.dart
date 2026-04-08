import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';

enum ResultActionButtonTone { primary, secondary, tertiary }

class ResultActionButton extends StatelessWidget {
  final String label;
  final String seal;
  final String? subtitle;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ResultActionButtonTone tone;

  const ResultActionButton({
    super.key,
    required this.label,
    required this.seal,
    required this.tone,
    this.subtitle,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(tone);
    final enabled = onPressed != null && !isLoading;
    final borderRadius = BorderRadius.circular(16);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: palette.borderColor, width: 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.background,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.shadowColor,
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: borderRadius,
            splashColor: palette.splashColor,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: palette.badgeFill,
                      border: Border.all(
                        color: palette.badgeBorder,
                        width: 0.9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(48),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  palette.labelColor,
                                ),
                              ),
                            )
                          : Text(
                              seal,
                              style: GoogleFonts.notoSerifTc(
                                color: palette.labelColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.notoSerif(
                            color: palette.labelColor,
                            fontSize: 14.4,
                            fontWeight: FontWeight.w700,
                            height: 1.08,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: GoogleFonts.cinzel(
                              color: palette.subtitleColor,
                              fontSize: 8.6,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              height: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ResultActionPalette _paletteFor(ResultActionButtonTone tone) {
    return switch (tone) {
      ResultActionButtonTone.primary => const _ResultActionPalette(
        background: [Color(0xFF8D2215), Color(0xFF62130B)],
        borderColor: Color(0xFFB4472E),
        badgeFill: Color(0xFF4F0F0A),
        badgeBorder: Color(0xFFD58F63),
        labelColor: Color(0xFFF6E2BE),
        subtitleColor: Color(0xFFE3B987),
        shadowColor: Color(0x7D250907),
        splashColor: Color(0x22F6C37A),
      ),
      ResultActionButtonTone.secondary => const _ResultActionPalette(
        background: [Color(0xFF4A2E17), Color(0xFF2A170B)],
        borderColor: Color(0xFF8F6A3B),
        badgeFill: Color(0xFF3E220D),
        badgeBorder: Color(0xFFD5B07A),
        labelColor: Color(0xFFF3E5C6),
        subtitleColor: Color(0xFFD7BC8A),
        shadowColor: Color(0x70000000),
        splashColor: Color(0x22D4AF37),
      ),
      ResultActionButtonTone.tertiary => const _ResultActionPalette(
        background: [Color(0xFF2D190E), Color(0xFF1A0E08)],
        borderColor: Color(0xFF6E512C),
        badgeFill: Color(0xFF241109),
        badgeBorder: Color(0xFFA47C46),
        labelColor: XiangqiColors.lacquerPanelText,
        subtitleColor: XiangqiColors.lacquerPanelMutedText,
        shadowColor: Color(0x66000000),
        splashColor: Color(0x22FFE4A1),
      ),
    };
  }
}

class _ResultActionPalette {
  final List<Color> background;
  final Color borderColor;
  final Color badgeFill;
  final Color badgeBorder;
  final Color labelColor;
  final Color subtitleColor;
  final Color shadowColor;
  final Color splashColor;

  const _ResultActionPalette({
    required this.background,
    required this.borderColor,
    required this.badgeFill,
    required this.badgeBorder,
    required this.labelColor,
    required this.subtitleColor,
    required this.shadowColor,
    required this.splashColor,
  });
}
