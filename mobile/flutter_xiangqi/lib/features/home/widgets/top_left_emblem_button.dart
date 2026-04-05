import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// A decorative circular emblem button placed in the top-left corner
/// of the start screen to match the web version's wuxia aesthetic.
/// Uses a styled text fallback ("将") since a specific asset is not available.
class TopLeftEmblemButton extends StatelessWidget {
  const TopLeftEmblemButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: XiangqiColors.bgDark.withAlpha(160), // Dark translucent inner fill
        border: Border.all(
          color: Colors.white.withAlpha(200), // White outer ring
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '将',
        style: XiangqiTextStyles.displayTitle.copyWith(
          fontSize: 22,
          color: Colors.white.withAlpha(230),
          height: 1.0,
          shadows: [],
        ),
      ),
    );
  }
}
