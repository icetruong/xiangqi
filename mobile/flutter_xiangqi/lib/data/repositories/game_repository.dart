import '../models/game_state_model.dart';
import '../models/move_request_model.dart';
import '../models/move_response_model.dart';

abstract class GameRepository {
  Future<GameStateModel> createGame(String difficulty, String playerSide);
  Future<GameStateModel> getGame(String gameId);
  Future<MoveResponseModel> makeMove(String gameId, MoveRequestModel request);
  Future<void> resignGame(String gameId);
  Future<void> drawGame(String gameId);
}
