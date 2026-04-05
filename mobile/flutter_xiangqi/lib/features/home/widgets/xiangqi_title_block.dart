import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

/// The title block inside the centered panel.
///
/// Renders (top → bottom) matching the web's `.title-crest` / `.game-title` / `.subtitle`:
///   • Gold-bordered circle with 将 character
///   • "XIANGQI" in Cinzel, 40 px, warm ink-brown, letter-spaced
///   • "PREPARE FOR BATTLE" in Cinzel, small, letter-spaced, muted brown
class XiangqiTitleBlock extends StatelessWidget {
  const XiangqiTitleBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 将 emblem circle (title-crest) ───────────────────────────────────
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: XiangqiColors.parchment,
            border: Border.all(color: XiangqiColors.gold, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '将',
            style: GoogleFonts.notoSerifSc(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: XiangqiColors.textTitle,
              height: 1,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── XIANGQI ──────────────────────────────────────────────────────────
        // Web: font-size 46px, letter-spacing 5px, color #4a2c0a
        Text('XIANGQI', style: XiangqiTextStyles.displayTitle),

        const SizedBox(height: 6),

        // ── PREPARE FOR BATTLE ───────────────────────────────────────────────
        // Web: font-size 13px, letter-spacing 3px, color #7a5020
        Text('PREPARE FOR BATTLE', style: XiangqiTextStyles.subtitle),
      ],
    );
  }
}
