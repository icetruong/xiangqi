import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Ornamental horizontal divider matching the web version's `.ornamental-divider`.
///
/// Structure:
///   ────────────────── ✦ ──────────────────
///
/// Thin lines fade from transparent → gold → transparent.
/// The centre ornament is the Unicode character `✦` (U+2726) in gold.
class OrnamentDivider extends StatelessWidget {
  final double verticalPadding;

  const OrnamentDivider({super.key, this.verticalPadding = 12});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        children: [
          // Left fading line
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0x80A06B2A), // ~50% gold
                    Color(0x80A06B2A),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Centre ornament — matching web `.ornamental-divider span` with `✦`
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '✦',
              style: TextStyle(
                fontSize: 10,
                color: XiangqiColors.gold.withAlpha(191), // ~75% opacity
                height: 1,
              ),
            ),
          ),

          // Right fading line
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x80A06B2A),
                    Color(0x80A06B2A),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
