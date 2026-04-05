import 'package:flutter/material.dart';

/// Slim in-flow banner shown while the AI is computing its reply.
///
/// This is intentionally lightweight: it sits _between_ the status banner and
/// the board, never blocking the board itself.  The full-screen overlay in
/// [GameScreen] continues to render for [isAiThinking] to absorb taps.
///
/// Usage: always include this widget in the layout column; it collapses to
/// zero height when [visible] is false, keeping the layout stable.
class AiThinkingIndicator extends StatefulWidget {
  final bool visible;

  const AiThinkingIndicator({super.key, required this.visible});

  @override
  State<AiThinkingIndicator> createState() => _AiThinkingIndicatorState();
}

class _AiThinkingIndicatorState extends State<AiThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: widget.visible ? _buildBanner() : const SizedBox.shrink(),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: const Color(0xFF2A1800), // dark amber-brown
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _pulse,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD4AF37), // antique gold
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'AI is thinking…',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFFFE082), // warm gold text
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
