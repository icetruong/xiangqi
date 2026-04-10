import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../core/persistence/game_persistence_service.dart';

/// A themed "Continue Game" card shown on the home screen when a resumable
/// session exists. Visually consistent with the parchment panel and StartButton.
///
/// Layout:
///   [将 glyph]  [meta text: difficulty / side]  [CONTINUE →]
class ContinueGameCard extends StatefulWidget {
  final SavedGameSession session;
  final VoidCallback onContinue;

  const ContinueGameCard({
    super.key,
    required this.session,
    required this.onContinue,
  });

  @override
  State<ContinueGameCard> createState() => _ContinueGameCardState();
}

class _ContinueGameCardState extends State<ContinueGameCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.reverse();
  void _onTapUp(_) => _ctrl.forward();
  void _onTapCancel() => _ctrl.forward();

  String get _sideLabel =>
      widget.session.playerSide == 'r' ? 'Red (先)' : 'Black (後)';

  String get _diffLabel {
    final d = widget.session.difficulty;
    return '${d[0].toUpperCase()}${d.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onContinue,
        child: Container(
          decoration: BoxDecoration(
            // Subtle lacquer-gold gradient — distinguishes from parchment
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A2C0A), // warm dark brown
                Color(0xFF3A1C0A), // deeper
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0x99CAA76A), // 60% gold
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // ── 将 emblem ───────────────────────────────────────────────
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8C1318),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 6,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '将',
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF5E8C0),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ── Meta text ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTINUE GAME',
                      style: GoogleFonts.cinzel(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: XiangqiColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$_diffLabel · $_sideLabel',
                      style: GoogleFonts.notoSerif(
                        fontSize: 12,
                        color: const Color(0xFFD4B87A),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Arrow ─────────────────────────────────────────────────────
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFFCAA76A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
