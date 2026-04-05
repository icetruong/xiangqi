import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// A refined, faithful adaptation of the web screenshot's top-left emblem.
/// Features a dark translucent fill, thin crisp white border, and centered "将".
class TopLeftEmblemBadge extends StatelessWidget {
  const TopLeftEmblemBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x73000000), // Dark transparent inner fill (approx 45% black)
        border: Border.all(
          color: Colors.white.withAlpha(220), // Thin crisp white outer ring
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000), // Soft shadow behind
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '将',
        // We use Noto Serif fallback for the Chinese character to ensure an elegant serif look.
        style: XiangqiTextStyles.displayTitle.copyWith(
          fontSize: 20,
          color: Colors.white,
          height: 1.1,
          fontFamily: 'Noto Serif', // Ensure elegant Chinese serif 
          shadows: [],
        ),
      ),
    );
  }
}
