import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/board_layout.dart';
import '../../../core/utils/board_visual_config.dart';
import '../utils/board_piece_locator.dart';

class CheckEffectOverlay extends StatefulWidget {
  final BoardPieceLocation? checkedGeneral;
  final double boardW;
  final double boardH;

  const CheckEffectOverlay({
    super.key,
    required this.checkedGeneral,
    required this.boardW,
    required this.boardH,
  });

  @override
  State<CheckEffectOverlay> createState() => _CheckEffectOverlayState();
}

class _CheckEffectOverlayState extends State<CheckEffectOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _burstController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _syncAnimation(null, widget.checkedGeneral);
  }

  @override
  void didUpdateWidget(covariant CheckEffectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation(oldWidget.checkedGeneral, widget.checkedGeneral);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkedGeneral = widget.checkedGeneral;
    if (checkedGeneral == null) {
      return const SizedBox.shrink();
    }

    final boardCell = math.min(
      BoardLayout.cellWidth(widget.boardW),
      BoardLayout.cellHeight(widget.boardH),
    );
    final pieceSize = BoardLayout.pieceSize(widget.boardW, widget.boardH);
    final centre = BoardLayout.intersectionOffset(
      checkedGeneral.row,
      checkedGeneral.col,
      widget.boardW,
      widget.boardH,
    );
    final auraSize = pieceSize * 2.15;
    final innerRingStroke = math.max(
      1.8,
      BoardVisualConfig.scaledPx(2.8, boardCell),
    );
    final outerRingStroke = math.max(
      1.2,
      BoardVisualConfig.scaledPx(1.8, boardCell),
    );

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _burstController]),
        builder: (context, child) {
          final pulse = Curves.easeInOut.transform(_pulseController.value);
          final burst = Curves.easeOutCubic.transform(_burstController.value);
          final auraOpacity = 0.24 + ((1 - pulse) * 0.12);
          final auraScale = 1.0 + (pulse * 0.12);
          final outerScale = 1.08 + (pulse * 0.16);
          final burstScale = 0.9 + (burst * 0.62);
          final burstOpacity = (1 - burst).clamp(0.0, 1.0) * 0.72;

          return Stack(
            children: [
              Positioned(
                left: centre.dx - (auraSize / 2),
                top: centre.dy - (auraSize / 2),
                child: SizedBox(
                  width: auraSize,
                  height: auraSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: auraScale,
                        child: Container(
                          width: auraSize,
                          height: auraSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.1, -0.16),
                              radius: 0.9,
                              colors: [
                                const Color(0x26FFE6BF),
                                Color.lerp(
                                  const Color(0x6AE24C35),
                                  const Color(0x88F29B2E),
                                  pulse * 0.35,
                                )!,
                                const Color(0x00F29B2E),
                              ],
                              stops: const [0.0, 0.52, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0x68A1120C,
                                ).withAlpha((auraOpacity * 255).round()),
                                blurRadius: auraSize * 0.18,
                                spreadRadius: auraSize * 0.02,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (burstOpacity > 0.01)
                        Opacity(
                          opacity: burstOpacity,
                          child: Transform.scale(
                            scale: burstScale,
                            child: _EffectRing(
                              size: auraSize * 0.9,
                              strokeWidth: outerRingStroke,
                              color: const Color(0xFFF6C07B),
                              shadowColor: const Color(0x88F87A4B),
                            ),
                          ),
                        ),
                      Transform.scale(
                        scale: 0.98 + (pulse * 0.08),
                        child: _EffectRing(
                          size: pieceSize * 1.28,
                          strokeWidth: innerRingStroke,
                          color: const Color(0xFFF5C47A),
                          shadowColor: const Color(0xAAE2553B),
                        ),
                      ),
                      Transform.scale(
                        scale: outerScale,
                        child: _EffectRing(
                          size: pieceSize * 1.52,
                          strokeWidth: outerRingStroke,
                          color: const Color(0xA8F25A40),
                          shadowColor: const Color(0x55FFAE4D),
                        ),
                      ),
                      Container(
                        width: pieceSize * 0.96,
                        height: pieceSize * 0.96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x90FFFFFF),
                            width: math.max(0.8, innerRingStroke * 0.42),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0x55FF8A5F,
                              ).withAlpha(
                                ((0.35 + ((1 - pulse) * 0.2)) * 255).round(),
                              ),
                              blurRadius: pieceSize * 0.12,
                              spreadRadius: pieceSize * 0.01,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _syncAnimation(
    BoardPieceLocation? previous,
    BoardPieceLocation? current,
  ) {
    final previousKey = _locationKey(previous);
    final currentKey = _locationKey(current);

    if (currentKey == null) {
      _pulseController.stop();
      _burstController.stop();
      _pulseController.value = 0;
      _burstController.value = 0;
      return;
    }

    if (!_pulseController.isAnimating) {
      _pulseController.repeat();
    }

    if (previousKey != currentKey) {
      _burstController.forward(from: 0);
    }
  }

  String? _locationKey(BoardPieceLocation? location) {
    if (location == null) {
      return null;
    }
    return '${location.row}:${location.col}:${location.piece.code}';
  }
}

class _EffectRing extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  final Color shadowColor;

  const _EffectRing({
    required this.size,
    required this.strokeWidth,
    required this.color,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: strokeWidth),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: size * 0.12,
            spreadRadius: size * 0.01,
          ),
        ],
      ),
    );
  }
}
