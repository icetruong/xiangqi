import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// The scroll-panel frame that wraps all home screen content.
///
/// Visually replicates the web's `.plaque-frame` + `.plaque-content` structure:
///
///   • Aged ivory parchment body with subtle top-sheen gradient
///   • Thin warm-brown border lines (not thick gold)
///   • Top and bottom "scroll rod" bars — golden-wood gradient, extending
///     slightly beyond the panel edges, with small end-knob circles
///   • Small gold corner-pin circles at the four panel corners
///   • Heavy drop shadow beneath the whole frame
///   • Ambient glow around the panel (warm ivory radial gradient)
class FramedPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double cornerSize;

  const FramedPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
    this.cornerSize = 14,
  });

  // Rod geometry — matches web: `left: -14px; right: -14px; height: 13px`
  static const double _rodOverhang = 14; // px each side
  static const double _rodHeight   = 13;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Ambient glow behind panel ────────────────────────────────────────
        Positioned.fill(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF0DCAA).withAlpha(72),  // 28% ivory
                    const Color(0xFFC8A05A).withAlpha(31),  // 12% gold
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 0.75],
                ),
              ),
            ),
          ),
        ),

        // ── Main parchment body ──────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(vertical: _rodHeight),
          padding: padding,
          decoration: XiangqiDecorations.panel,
          child: child,
        ),

        // ── TOP scroll rod ───────────────────────────────────────────────────
        Positioned(
          top: 0,
          left: -_rodOverhang,
          right: -_rodOverhang,
          height: _rodHeight,
          child: _ScrollRod(top: true),
        ),

        // ── BOTTOM scroll rod ────────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: -_rodOverhang,
          right: -_rodOverhang,
          height: _rodHeight,
          child: _ScrollRod(top: false),
        ),

        // ── Corner pins (on top of rods) ─────────────────────────────────────
        Positioned(
          top: -cornerSize / 2 + _rodHeight / 2,
          left: -cornerSize / 2,
          child: _CornerPin(size: cornerSize),
        ),
        Positioned(
          top: -cornerSize / 2 + _rodHeight / 2,
          right: -cornerSize / 2,
          child: _CornerPin(size: cornerSize),
        ),
        Positioned(
          bottom: -cornerSize / 2 + _rodHeight / 2,
          left: -cornerSize / 2,
          child: _CornerPin(size: cornerSize),
        ),
        Positioned(
          bottom: -cornerSize / 2 + _rodHeight / 2,
          right: -cornerSize / 2,
          child: _CornerPin(size: cornerSize),
        ),
      ],
    );
  }
}

// ── Scroll rod bar ─────────────────────────────────────────────────────────

class _ScrollRod extends StatelessWidget {
  final bool top;
  const _ScrollRod({required this.top});

  static const _kGrad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: XiangqiColors.scrollRodColors,
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  static const double _knobSize   = 19;
  static const double _knobOffset = -3;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Rod bar
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: _kGrad,
            boxShadow: const [
              BoxShadow(
                color: Color(0x73000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        // Left end knob
        Positioned(
          top: _knobOffset,
          left: -4,
          child: _RodKnob(size: _knobSize),
        ),
        // Right end knob
        Positioned(
          top: _knobOffset,
          right: -4,
          child: _RodKnob(size: _knobSize),
        ),
      ],
    );
  }
}

// ── Rod end knob ───────────────────────────────────────────────────────────

class _RodKnob extends StatelessWidget {
  final double size;
  const _RodKnob({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD4A94A),
            Color(0xFF7E4E1A),
            Color(0xFFC09040),
          ],
          stops: [0.0, 0.60, 1.0],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

// ── Corner pin ─────────────────────────────────────────────────────────────

class _CornerPin extends StatelessWidget {
  final double size;
  const _CornerPin({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD4AF37),
            Color(0xFF8B692A),
          ],
        ),
        border: Border.all(color: const Color(0xFF8B692A), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}
