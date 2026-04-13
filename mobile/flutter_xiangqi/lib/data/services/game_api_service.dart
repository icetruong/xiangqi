import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../models/game_state_model.dart';
import '../models/move_request_model.dart';
import '../models/move_response_model.dart';

class GameApiService {
  final Dio _dio;

  GameApiService(this._dio);

  Future<GameStateModel> createGame(String difficulty, String playerSide) async {
    try {
      final requestUrl = '${_dio.options.baseUrl}${ApiConstants.games}';
      debugPrint('DEBUG [GameApiService]: POST createGame at $requestUrl');
      final response = await _dio.post(
        ApiConstants.games,
        data: {
          'difficulty': difficulty,
          'player_side': playerSide,
        },
      );
      return GameStateModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('DEBUG [GameApiService]: DioException in createGame! Type: ${e.type}, Message: ${e.message}');
      if (e.response != null) {
        debugPrint('DEBUG [GameApiService]: Error Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<GameStateModel> getGame(String gameId) async {
    final response = await _dio.get(ApiConstants.gameDetail(gameId));
    return GameStateModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MoveResponseModel> makeMove(String gameId, MoveRequestModel request) async {
    final requestUrl = '${_dio.options.baseUrl}${ApiConstants.gameMove(gameId)}';
    debugPrint('DEBUG [GameApiService]: POST makeMove for gameId $gameId at $requestUrl');
    debugPrint('DEBUG [GameApiService]: Request payload: ${request.toJson()}');
    
    try {
      final response = await _dio.post(
        ApiConstants.gameMove(gameId),
        data: request.toJson(),
      );
      return MoveResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('DEBUG [GameApiService]: DioException in makeMove! StatusCode: ${e.response?.statusCode}');
      if (e.response != null) {
        debugPrint('DEBUG [GameApiService]: Error Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resignGame(String gameId) async {
    final response = await _dio.post(ApiConstants.gameResign(gameId));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> drawGame(String gameId) async {
    final response = await _dio.post(ApiConstants.gameDraw(gameId));
    return response.data as Map<String, dynamic>;
  }
}
