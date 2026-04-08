import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';

class CheckWarningBanner extends StatelessWidget {
  final String? checkedSide;
  final String? playerSide;
  final EdgeInsetsGeometry? margin;

  const CheckWarningBanner({
    super.key,
    required this.checkedSide,
    required this.playerSide,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isVisible = checkedSide == 'r' || checkedSide == 'b';
    final isPlayerChecked = isVisible && checkedSide == playerSide;
    final title = isPlayerChecked
        ? 'Chiếu tướng!'
        : 'Tướng đối phương bị chiếu';
    final subtitle = isPlayerChecked
        ? 'Tướng của bạn đang bị uy hiếp.'
        : 'Áp lực đã dồn thẳng vào cung tướng.';

    return IgnorePointer(
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        offset: isVisible ? Offset.zero : const Offset(0, -0.18),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          opacity: isVisible ? 1 : 0,
          child: Container(
            margin: margin ?? const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xB8D29A48), width: 0.9),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xF0551E13),
                  Color(0xF034130B),
                  Color(0xF01F0B06),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x992A0905),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
                BoxShadow(
                  color: const Color(0x66E29D3C),
                  blurRadius: 18,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xD7F0CF99),
                      width: 0.9,
                    ),
                    gradient: const RadialGradient(
                      center: Alignment(-0.18, -0.24),
                      radius: 0.92,
                      colors: [
                        Color(0xFFE0614F),
                        Color(0xFF9B2418),
                        Color(0xFF5C120D),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '將',
                      style: GoogleFonts.notoSerifTc(
                        color: XiangqiColors.parchment,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSerif(
                        color: const Color(0xFFF8E6C2),
                        fontSize: 14.2,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.cinzel(
                        color: const Color(0xFFE2BE82),
                        fontSize: 8.9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
