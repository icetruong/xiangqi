import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class GameTopHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const GameTopHeader({
    super.key,
    required this.onBack,
    required this.onRefresh,
  });

  static const double _toolbarHeight = 74;
  static const double _controlSlotWidth = 76;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: _toolbarHeight,
      backgroundColor: Colors.transparent,
      foregroundColor: XiangqiColors.goldLight,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      leadingWidth: _controlSlotWidth,
      flexibleSpace: const _HeaderBackdrop(),
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: 14,
          top: 10,
          bottom: 10,
        ),
        child: _HeaderActionButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back to home',
          onPressed: onBack,
        ),
      ),
      title: const _PremiumHeaderTitle(),
      actions: [
        SizedBox(
          width: _controlSlotWidth,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              end: 14,
              top: 10,
              bottom: 10,
            ),
            child: _HeaderActionButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Refresh game',
              onPressed: onRefresh,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderBackdrop extends StatelessWidget {
  const _HeaderBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5A2816),
            Color(0xFF3C180B),
            Color(0xFF241007),
          ],
          stops: [0.0, 0.46, 1.0],
        ),
        border: const Border(
          top: BorderSide(color: Color(0x338C5E26), width: 1),
          bottom: BorderSide(color: Color(0x66C9944A), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x8A110803),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withAlpha(18),
                    Colors.transparent,
                    Colors.black.withAlpha(40),
                  ],
                  stops: const [0.0, 0.32, 1.0],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 18,
            right: 18,
            bottom: 0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0x009C7637),
                      Color(0x66D4AF37),
                      Color(0x009C7637),
                    ],
                  ),
                ),
                child: SizedBox(height: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6A331A),
                Color(0xFF3A190B),
              ],
            ),
            border: Border.all(color: const Color(0xBFC89A49), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius,
            splashColor: XiangqiColors.lacquerPanelGlow,
            highlightColor: Colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withAlpha(22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    icon,
                    size: 22,
                    color: const Color(0xFFF3D78E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumHeaderTitle extends StatelessWidget {
  const _PremiumHeaderTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF9E8BD),
                Color(0xFFE0BC6A),
                Color(0xFF9E712B),
              ],
              stops: [0.0, 0.48, 1.0],
            ).createShader(bounds);
          },
          child: Text(
            'XIANGQI',
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: XiangqiTextStyles.gameHeaderTitle,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _OrnamentLine(),
            SizedBox(width: 8),
            _TitleDiamond(),
            SizedBox(width: 8),
            _OrnamentLine(),
          ],
        ),
      ],
    );
  }
}

class _OrnamentLine extends StatelessWidget {
  const _OrnamentLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            XiangqiColors.gold.withAlpha(0),
            XiangqiColors.gold.withAlpha(210),
            XiangqiColors.gold.withAlpha(0),
          ],
        ),
      ),
    );
  }
}

class _TitleDiamond extends StatelessWidget {
  const _TitleDiamond();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: const Color(0xFFD7B15D),
          borderRadius: BorderRadius.circular(1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66381C06),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
