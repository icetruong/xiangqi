import 'dart:ui';
import 'package:flutter/material.dart';

import 'rules_book_modal.dart';

/// Shows the modular rules overlay. 
/// It blurs the underlying screen and presents the parchment book modal.
void showRulesOverlay(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(128), // Dimmed background
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: const RulesBookModal(),
          ),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // A subtle slide-up and fade-in
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    ),
  );
}
