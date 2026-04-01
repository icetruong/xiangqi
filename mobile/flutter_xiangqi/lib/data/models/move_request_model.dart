class MoveRequestModel {
  final List<int> from;
  final List<int> to;

  MoveRequestModel({
    required this.from,
    required this.to,
  });

  factory MoveRequestModel.fromJson(Map<String, dynamic> json) {
    return MoveRequestModel(
      from: List<int>.from(json['from'] as List),
      to: List<int>.from(json['to'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
    };
  }
}
