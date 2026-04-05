import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// A text link in the top-right cluster, uppercase serif, ivory/light beige.
class HeaderTextLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const HeaderTextLink({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            text.toUpperCase(),
            style: XiangqiTextStyles.subtitle.copyWith(
              color: const Color(0xFFF7F0E0), // Ivory matching parchment
              fontSize: 12,
              letterSpacing: 2.5,
              shadows: const [
                Shadow(
                  color: Color(0xCC000000), // Drop shadow for readability
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
