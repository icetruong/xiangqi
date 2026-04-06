import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/utils/piece_mapper.dart';
import '../../../data/models/move_model.dart';

/// Compact horizontal move history shown directly below the board.
///
/// Older moves stay on the left, the newest move stays on the right, and the
/// strip auto-scrolls to the latest entry whenever a new move arrives.
class MoveHistoryStrip extends StatefulWidget {
  final List<MoveModel> moveHistory;

  const MoveHistoryStrip({super.key, required this.moveHistory});

  @override
  State<MoveHistoryStrip> createState() => _MoveHistoryStripState();
}

class _MoveHistoryStripState extends State<MoveHistoryStrip> {
  final ScrollController _scrollController = ScrollController();
  String? _lastMoveSignature;

  @override
  void initState() {
    super.initState();
    _lastMoveSignature = _signature(_latestMove);
    _scrollToLatest(jump: true);
  }

  @override
  void didUpdateWidget(covariant MoveHistoryStrip oldWidget) {
    super.didUpdateWidget(oldWidget);

    final latestSignature = _signature(_latestMove);
    final didHistoryChange =
        widget.moveHistory.length != oldWidget.moveHistory.length ||
        latestSignature != _lastMoveSignature;

    if (!didHistoryChange) {
      return;
    }

    _lastMoveSignature = latestSignature;
    _scrollToLatest();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  MoveModel? get _latestMove =>
      widget.moveHistory.isEmpty ? null : widget.moveHistory.last;

  void _scrollToLatest({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final offset = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(offset);
        return;
      }

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String? _signature(MoveModel? move) {
    if (move == null || move.from.length < 2 || move.to.length < 2) {
      return null;
    }

    return '${move.piece ?? ''}:${move.from[0]},${move.from[1]}'
        '->${move.to[0]},${move.to[1]}:${move.captured ?? ''}:${move.ply ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final moves = widget.moveHistory;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: XiangqiColors.goldDark.withAlpha(165),
          width: 0.9,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xD9301408), Color(0xE1140904)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: moves.isEmpty
            ? const Center(
                child: Text(
                  'No moves yet',
                  style: TextStyle(
                    color: Color(0xFFD3BA8A),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : ScrollConfiguration(
                behavior: const _MoveStripScrollBehavior(),
                child: RawScrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  radius: const Radius.circular(999),
                  thickness: 6,
                  thumbColor: XiangqiColors.gold.withAlpha(230),
                  trackColor: const Color(0x453B2418),
                  trackBorderColor: Colors.transparent,
                  minThumbLength: 36,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: moves.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return _MoveChip(
                        move: moves[index],
                        fallbackPly: index + 1,
                        isLatest: index == moves.length - 1,
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

class _MoveStripScrollBehavior extends ScrollBehavior {
  const _MoveStripScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _MoveChip extends StatelessWidget {
  final MoveModel move;
  final int fallbackPly;
  final bool isLatest;

  const _MoveChip({
    required this.move,
    required this.fallbackPly,
    required this.isLatest,
  });

  @override
  Widget build(BuildContext context) {
    final pieceCode = move.piece;
    final side = _sideForMove(move);
    final isRed = side == 'r';
    final pieceLabel = _pieceLabel(pieceCode);
    final capturedLabel = _capturedLabel(move.captured);
    final ply = move.ply ?? fallbackPly;
    final textColor = isRed ? const Color(0xFFFFD3CD) : const Color(0xFFF0E6D6);
    final borderColor = isLatest
        ? XiangqiColors.goldLight.withAlpha(220)
        : (isRed ? const Color(0xE8B84B44) : const Color(0xD29A8E7B));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: isLatest ? 1.2 : 0.8),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isRed
              ? const [Color(0xFF6C231D), Color(0xFF471310)]
              : const [Color(0xFF3C3836), Color(0xFF232120)],
        ),
        boxShadow: isLatest
            ? const [
                BoxShadow(
                  color: Color(0x449E7D2B),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(
                text: '$ply. ',
                style: TextStyle(
                  color: XiangqiColors.gold.withAlpha(230),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (pieceLabel.isNotEmpty) TextSpan(text: '$pieceLabel '),
              TextSpan(text: _square(move.from)),
              const TextSpan(text: ' -> '),
              TextSpan(text: _square(move.to)),
              if (capturedLabel.isNotEmpty) TextSpan(text: ' x$capturedLabel'),
            ],
          ),
        ),
      ),
    );
  }

  String _sideForMove(MoveModel move) {
    final side = move.side;
    if (side == 'r' || side == 'b') {
      return side!;
    }

    final pieceCode = move.piece;
    if (pieceCode != null && pieceCode.length == 2) {
      return pieceCode[0];
    }

    return 'r';
  }

  String _pieceLabel(String? pieceCode) {
    if (pieceCode == null || pieceCode.length != 2) {
      return '';
    }

    return PieceMapper.chineseLabel(pieceCode[0], pieceCode[1].toUpperCase());
  }

  String _capturedLabel(String? pieceCode) {
    if (pieceCode == null || pieceCode.length != 2) {
      return '';
    }

    return PieceMapper.chineseLabel(pieceCode[0], pieceCode[1].toUpperCase());
  }

  String _square(List<int> square) {
    if (square.length < 2) {
      return '?';
    }
    return '${square[0]},${square[1]}';
  }
}
