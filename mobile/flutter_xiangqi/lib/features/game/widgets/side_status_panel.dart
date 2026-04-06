import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../core/utils/piece_mapper.dart';

/// Compact identity card used in the mobile bottom-versus strip.
class SideStatusPanel extends StatelessWidget {
  final String label;
  final String side;
  final bool isHighlighted;
  final bool isDimmed;

  const SideStatusPanel({
    super.key,
    required this.label,
    required this.side,
    required this.isHighlighted,
    required this.isDimmed,
  });

  @override
  Widget build(BuildContext context) {
    final isRed = side == 'r';
    final accentColor = isRed
        ? const Color(0xFFE57E67)
        : const Color(0xFFE7DBC5);
    final subtitle = isRed ? 'QUÂN ĐỎ' : 'QUÂN ĐEN';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isDimmed ? 0.62 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isHighlighted
                ? XiangqiColors.lacquerPanelOutline.withAlpha(232)
                : XiangqiColors.lacquerPanelBorder.withAlpha(215),
            width: isHighlighted ? 1.1 : 0.9,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3A1C0E),
              XiangqiColors.lacquerPanelMid,
              XiangqiColors.lacquerPanelBottom,
            ],
            stops: [0.0, 0.62, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isHighlighted ? 120 : 92),
              blurRadius: isHighlighted ? 16 : 10,
              offset: const Offset(0, 5),
            ),
            if (isHighlighted)
              BoxShadow(
                color: XiangqiColors.goldLight.withAlpha(34),
                blurRadius: 18,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: XiangqiColors.lacquerPanelOutline.withAlpha(
                        isHighlighted ? 76 : 34,
                      ),
                      width: 0.55,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withAlpha(18),
                        Colors.transparent,
                        Colors.black.withAlpha(10),
                      ],
                      stops: const [0.0, 0.28, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _SideAvatar(
                  side: side,
                  accentColor: accentColor,
                  isHighlighted: isHighlighted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSerif(
                          color: XiangqiColors.lacquerPanelText.withAlpha(
                            isDimmed ? 204 : 255,
                          ),
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSerif(
                          color: accentColor.withAlpha(isDimmed ? 164 : 220),
                          fontSize: 8.6,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _TurnIndicator(
                  isHighlighted: isHighlighted,
                  accentColor: accentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SideAvatar extends StatelessWidget {
  final String side;
  final Color accentColor;
  final bool isHighlighted;

  const _SideAvatar({
    required this.side,
    required this.accentColor,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    final label = PieceMapper.chineseLabel(side, 'K');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.24, -0.32),
          radius: 0.86,
          colors: [Color(0xFF6B4E2A), Color(0xFF3E2512), Color(0xFF1E0D06)],
          stops: [0.0, 0.45, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(128),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(color: XiangqiColors.lacquerPanelBorder, spreadRadius: 1),
          if (isHighlighted)
            BoxShadow(
              color: accentColor.withAlpha(70),
              blurRadius: 14,
              spreadRadius: 1.5,
            ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.notoSerifTc(
            color: XiangqiColors.parchment,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            height: 1,
            shadows: [
              Shadow(
                color: Colors.black.withAlpha(128),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurnIndicator extends StatelessWidget {
  final bool isHighlighted;
  final Color accentColor;

  const _TurnIndicator({
    required this.isHighlighted,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = isHighlighted
        ? XiangqiColors.goldLight
        : accentColor.withAlpha(116);
    final outlineColor = isHighlighted
        ? XiangqiColors.parchment.withAlpha(214)
        : accentColor.withAlpha(180);

    return SizedBox(
      width: 14,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isHighlighted ? 10 : 8,
          height: isHighlighted ? 10 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fillColor,
            border: Border.all(color: outlineColor, width: 0.8),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: XiangqiColors.goldLight.withAlpha(126),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
