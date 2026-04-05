import 'dart:ui';
import 'package:flutter/material.dart';

/// Full-screen cinematic background matching the web version's visual treatment:
///
///   Layer 1 – battle painting (portrait PNG, fills screen)
///   Layer 2 – subtle ImageFilter blur (matches web `filter: blur(1.5px)`)
///   Layer 3 – radial vignette (transparent centre → near-black edges)
///   Layer 4 – linear gradient (slight top/bottom darkening)
class HomeBackground extends StatelessWidget {
  const HomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Layer 1: battle painting ─────────────────────────────────────────
        Image.asset(
          'assets/images/bg/battle-bg-portrait.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, _, _) => Container(color: const Color(0xFF0A0503)),
        ),

        // ── Layer 2: blur (1.5px, matching web `filter: blur(1.5px)`) ────────
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
          child: const SizedBox.expand(),
        ),

        // ── Layer 3: strong radial vignette — dark edges, clear centre ────────
        // Matches web: `radial-gradient(ellipse 85% 85%, transparent 20%, rgba(0,0,0,.95) 100%)`
        // plus `inset 0 0 120px 60px rgba(0,0,0,.7)` / `inset 0 0 260px 120px rgba(0,0,0,.65)`
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [
                Color(0x00000000), // transparent centre
                Color(0x88000000), // mid-dark (55%)
                Color(0xEE000000), // near-black edges (93%)
              ],
              stops: [0.20, 0.65, 1.0],
            ),
          ),
        ),

        // ── Layer 4: linear gradient (top/bottom dim, lighter centre) ─────────
        // Matches web background-image radial-gradient layer 2 warm centre
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x99000000), // top dim
                Color(0x11000000), // almost clear centre
                Color(0x99000000), // bottom dim
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
