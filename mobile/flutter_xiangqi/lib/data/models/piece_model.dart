class PieceModel {
  final String code;
  final String? color;
  final String? type;

  PieceModel({required this.code})
      : color = code.isNotEmpty ? code[0] : null,
        type = code.length > 1 ? code[1] : null;

  factory PieceModel.fromJson(String json) {
    return PieceModel(code: json);
  }

  String toJson() => code;

  bool get isEmpty => code.isEmpty;
  bool get isRed => color == 'r';
  bool get isBlack => color == 'b';
}
