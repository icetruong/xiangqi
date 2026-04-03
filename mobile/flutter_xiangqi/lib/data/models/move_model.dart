class MoveModel {
  final List<int> from;
  final List<int> to;
  final String? piece;
  final String? captured;

  /// Half-move number (1-indexed). Null when parsed from a bare last_move entry.
  final int? ply;

  /// Side that made this move: 'r' or 'b'. Null for bare last_move entries.
  final String? side;

  const MoveModel({
    required this.from,
    required this.to,
    this.piece,
    this.captured,
    this.ply,
    this.side,
  });

  factory MoveModel.fromJson(Map<String, dynamic> json) {
    return MoveModel(
      from: List<int>.from(json['from'] as List),
      to: List<int>.from(json['to'] as List),
      piece: json['piece'] as String?,
      captured: json['captured'] as String?,
      ply: json['ply'] as int?,
      side: json['side'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'piece': piece,
      'captured': captured,
      'ply': ply,
      'side': side,
    };
  }
}
