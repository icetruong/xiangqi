import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// PRIMARY ACTION BUTTON — "START GAME"
///
/// Visually replicates the web's `.start-button`:
///   • Full-width red lacquer gradient: `#c42028 → #8c1318` (180°)
///   • Thin gold border: `rgba(181,134,42,0.5)` — 1px
///   • Inner highlight: faint top sheen
///   • Drop shadow beneath
///   • Cinzel text, warm ivory `#f5e8c0`, letter-spaced 5px
///   • Slight scale press animation (96 % scale on tap)
class StartButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const StartButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<StartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
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
  void _onTapUp(_)   => _ctrl.forward();
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    final bool canPress = widget.onPressed != null && !widget.isLoading;

    return ScaleTransition(
      scale: _scale,
      child: MouseRegion(
        cursor: canPress ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown:  canPress ? _onTapDown  : null,
          onTapUp:    canPress ? _onTapUp    : null,
          onTapCancel: canPress ? _onTapCancel : null,
          onTap:       canPress ? widget.onPressed : null,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              // Red lacquer gradient — web: linear-gradient(180deg, #c42028 0%, #8c1318 100%)
              gradient: canPress
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFC42028), // crimson top
                        Color(0xFF8C1318), // dark red bottom
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF7A2020), // disabled top
                        Color(0xFF4A0E12), // disabled bottom
                      ],
                    ),
              borderRadius: BorderRadius.circular(3),
              // Gold border — web: 1px solid rgba(181,134,42,0.5)
              border: Border.all(
                color: const Color(0x80B5862A), // 50% gold
                width: 1,
              ),
              boxShadow: canPress
                  ? const [
                      // Drop shadow — web: 0 4px 14px rgba(0,0,0,0.45)
                      BoxShadow(
                        color: Color(0x73000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                      // Inner top highlight — simulated with a second shadow
                      BoxShadow(
                        color: Color(0x4DFFD26E), // faint gold top highlight
                        blurRadius: 2,
                        offset: Offset(0, 1),
                        spreadRadius: -1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC8B882)),
                    ),
                  )
                : Text(
                    'START GAME',
                    style: XiangqiTextStyles.startButton.copyWith(
                      color: canPress
                          ? const Color(0xFFF5E8C0) // warm ivory
                          : const Color(0xFFC8B882), // dimmed when disabled
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
