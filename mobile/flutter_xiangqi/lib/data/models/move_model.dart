class MoveModel {
  final List<int> from;
  final List<int> to;
  final String? piece;
  final String? captured;

  MoveModel({
    required this.from,
    required this.to,
    this.piece,
    this.captured,
  });

  factory MoveModel.fromJson(Map<String, dynamic> json) {
    return MoveModel(
      from: List<int>.from(json['from'] as List),
      to: List<int>.from(json['to'] as List),
      piece: json['piece'] as String?,
      captured: json['captured'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'piece': piece,
      'captured': captured,
    };
  }
}
