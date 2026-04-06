import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';

/// Compact center medallion between the two side panels.
class VersusCenterBadge extends StatelessWidget {
  const VersusCenterBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: XiangqiColors.lacquerPanelOutline.withAlpha(225),
              width: 1,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5B3417), Color(0xFF261108), Color(0xFF160904)],
              stops: [0.0, 0.45, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(160),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: XiangqiColors.goldLight.withAlpha(34),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              'VS',
              style: GoogleFonts.cinzel(
                color: XiangqiColors.goldLight,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(150),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
