import '../models/game_state_model.dart';
import '../models/move_request_model.dart';
import '../models/move_response_model.dart';
import '../services/game_api_service.dart';
import 'game_repository.dart';

class GameRepositoryImpl implements GameRepository {
  final GameApiService _apiService;

  GameRepositoryImpl(this._apiService);

  @override
  Future<GameStateModel> createGame(String difficulty, String playerSide) {
    return _apiService.createGame(difficulty, playerSide);
  }

  @override
  Future<GameStateModel> getGame(String gameId) {
    return _apiService.getGame(gameId);
  }

  @override
  Future<MoveResponseModel> makeMove(String gameId, MoveRequestModel request) {
    return _apiService.makeMove(gameId, request);
  }

  @override
  Future<void> resignGame(String gameId) async {
    await _apiService.resignGame(gameId);
  }

  @override
  Future<void> drawGame(String gameId) async {
    await _apiService.drawGame(gameId);
  }
}
