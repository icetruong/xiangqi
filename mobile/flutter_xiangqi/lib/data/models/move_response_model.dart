import 'game_state_model.dart';

class MoveResponseModel {
  final bool ok;
  final GameStateModel gameState;

  MoveResponseModel({
    required this.ok,
    required this.gameState,
  });

  factory MoveResponseModel.fromJson(Map<String, dynamic> json) {
    return MoveResponseModel(
      ok: json['ok'] as bool? ?? false,
      gameState: GameStateModel.fromJson(json), // reusing parsing since the fields overlap
    );
  }

  Map<String, dynamic> toJson() {
    final stateJson = gameState.toJson();
    stateJson['ok'] = ok;
    return stateJson;
  }
}
