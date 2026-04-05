import 'package:flutter/material.dart';

import '../../rules/widgets/rules_overlay.dart';
import 'header_text_link.dart';
import 'music_control_box.dart';

/// The horizontal control cluster for the top-right corner, recreating
/// the web layout precisely: [ Music Box ]   RULES   ABOUT.
class TopRightHeaderCluster extends StatelessWidget {
  const TopRightHeaderCluster({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const MusicControlBox(),
        const SizedBox(width: 6),
        HeaderTextLink(
          text: 'RULES',
          onTap: () {
            showRulesOverlay(context);
          },
        ),
        HeaderTextLink(
          text: 'ABOUT',
          onTap: () {
            // TODO: Hook up to About panel/dialog if it exists
          },
        ),
      ],
    );
  }
}
