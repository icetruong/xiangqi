import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/persistence_providers.dart';
import '../../data/models/game_state_model.dart';
import '../../data/models/move_request_model.dart';
import '../../data/providers.dart';
import 'models/game_action_type.dart';
import 'state/game_ui_state.dart';

/// Loads and refreshes the persisted game state from the backend.
class GameController extends AsyncNotifier<GameStateModel> {
  GameController(this.gameId);

  final String gameId;
  static const Duration _pollInterval = Duration(milliseconds: 650);

  Timer? _pollTimer;
  bool _isPollRequestInFlight = false;
  int _pollGeneration = 0;

  @override
  Future<GameStateModel> build() async {
    ref.onDispose(_stopPolling);
    final game = await ref.read(gameRepositoryProvider).getGame(gameId);
    _syncPollingFor(game, source: 'build');
    return game;
  }

  Future<void> refreshGame() async {
    _stopPolling();
    state = const AsyncValue.loading();
    try {
      final refreshed = await ref.read(gameRepositoryProvider).getGame(gameId);
      _setStateWithPolling(refreshed, source: 'refreshGame');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void replaceState(GameStateModel updated) {
    _setStateWithPolling(updated, source: 'replaceState');
  }

  void applyOptimisticPlayerMove(
    GameStateModel current, {
    required int fromRow,
    required int fromCol,
    required int toRow,
    required int toCol,
  }) {
    _stopPolling();
    state = AsyncValue.data(
      current.optimisticPlayerMove(
        fromRow: fromRow,
        fromCol: fromCol,
        toRow: toRow,
        toCol: toCol,
      ),
    );
  }

  /// Applies the authoritative state returned by the move endpoint.
  void applyMoveResponse(GameStateModel updated) {
    _setStateWithPolling(updated, source: 'applyMoveResponse');
  }

  void _startPolling() {
    if (_pollTimer != null && _pollTimer!.isActive) {
      debugPrint('[Poll] Already polling, skipped duplicate start');
      return;
    }

    final generation = ++_pollGeneration;
    debugPrint(
      '[Poll] START polling game $gameId every '
      '${_pollInterval.inMilliseconds} ms',
    );

    unawaited(_pollOnce(generation));
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_pollOnce(generation));
    });
  }

  Future<void> _pollOnce(int generation) async {
    if (_isPollRequestInFlight) {
      return;
    }

    _isPollRequestInFlight = true;
    try {
      final newState = await ref.read(gameRepositoryProvider).getGame(gameId);
      if (generation != _pollGeneration) {
        return;
      }
      state = AsyncValue.data(newState);

      debugPrint(
        '[Poll] currentTurn=${newState.currentTurn} '
        'playerSide=${newState.playerSide} '
        'status=${newState.status} '
        'isAiThinking=${newState.isAiThinking}',
      );

      if (!_shouldPoll(newState)) {
        _stopPolling();
      }
    } catch (e) {
      if (generation == _pollGeneration) {
        debugPrint('[Poll] Error during poll: $e');
      }
    } finally {
      if (generation == _pollGeneration) {
        _isPollRequestInFlight = false;
      }
    }
  }

  void _stopPolling() {
    final wasPolling = _pollTimer != null || _isPollRequestInFlight;
    _pollGeneration++;
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPollRequestInFlight = false;
    if (wasPolling) {
      debugPrint('[Poll] STOP polling game $gameId');
    }
  }

  void _setStateWithPolling(GameStateModel updated, {required String source}) {
    state = AsyncValue.data(updated);
    _syncPollingFor(updated, source: source);
    // Clear persisted session as soon as the game leaves 'ongoing'
    if (updated.status != 'ongoing') {
      _clearPersistedSession();
    }
  }

  void _clearPersistedSession() {
    try {
      final service = ref.read(gamePersistenceServiceProvider);
      service.clearSession();
      debugPrint('[GameController] Cleared saved session for game $gameId');
    } catch (e) {
      debugPrint('[GameController] Failed to clear saved session: $e');
    }
  }

  void _syncPollingFor(GameStateModel updated, {required String source}) {
    final shouldPoll = _shouldPoll(updated);
    debugPrint(
      '[Poll] $source '
      'currentTurn=${updated.currentTurn} '
      'playerSide=${updated.playerSide} '
      'status=${updated.status} '
      'isAiThinking=${updated.isAiThinking} '
      'willPoll=$shouldPoll',
    );

    if (shouldPoll) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  bool _shouldPoll(GameStateModel game) {
    final playerSide = _normalizedSide(game.playerSide);
    return game.status == 'ongoing' &&
        playerSide != null &&
        game.currentTurn != playerSide;
  }

  String? _normalizedSide(String? side) {
    if (side == 'r' || side == 'b') {
      return side;
    }
    return null;
  }
}

final gameControllerProvider = AsyncNotifierProvider.autoDispose
    .family<GameController, GameStateModel, String>(GameController.new);

/// Manages selection, move submission, and transient UI errors.
class GameUiNotifier extends Notifier<GameUiState> {
  GameUiNotifier(this.gameId);

  final String gameId;

  @override
  GameUiState build() => GameUiState.empty;

  void selectPiece(int row, int col, GameStateModel game) {
    final filtered = _filterLegalMovesFor(row, col, game.legalMoves);
    state = GameUiState(
      selectedRow: row,
      selectedCol: col,
      moveError: null,
      legalMovesForSelected: filtered,
    );
  }

  static List<List<int>>? _filterLegalMovesFor(
    int fromRow,
    int fromCol,
    List<dynamic>? legalMoves,
  ) {
    if (legalMoves == null || legalMoves.isEmpty) return null;
    try {
      final result = <List<int>>[];
      for (final m in legalMoves) {
        final map = m as Map<String, dynamic>;
        final from = map['from'] as List;
        if (from[0] as int == fromRow && from[1] as int == fromCol) {
          final to = map['to'] as List;
          result.add([to[0] as int, to[1] as int]);
        }
      }
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  void clearSelection() {
    state = GameUiState.empty;
  }

  Future<void> tapIntersection(int row, int col, GameStateModel game) async {
    if (state.isSubmitting || state.isPerformingAction || game.isAiThinking) {
      return;
    }

    final piece = game.boardState[row][col];
    final isOwnPiece = !piece.isEmpty && piece.color == game.currentTurn;

    if (!state.hasSelection) {
      if (isOwnPiece) {
        selectPiece(row, col, game);
      }
      return;
    }

    if (row == state.selectedRow && col == state.selectedCol) {
      clearSelection();
      return;
    }

    if (isOwnPiece) {
      selectPiece(row, col, game);
      return;
    }

    await _submitMove(game, state.selectedRow!, state.selectedCol!, row, col);
  }

  Future<GameStateModel?> submitGameAction(
    GameActionType action,
    GameStateModel currentGame,
  ) async {
    if (action == GameActionType.exit ||
        state.isSubmitting ||
        state.isPerformingAction ||
        currentGame.isAiThinking ||
        currentGame.status != 'ongoing') {
      return null;
    }

    state = state.copyWith(
      activeAction: action,
      clearError: true,
      clearSelection: true,
      clearLegal: true,
    );

    try {
      final repo = ref.read(gameRepositoryProvider);

      switch (action) {
        case GameActionType.resign:
          await repo.resignGame(gameId);
          break;
        case GameActionType.draw:
          await repo.drawGame(gameId);
          break;
        case GameActionType.exit:
          return null;
      }

      final updatedGame = await repo.getGame(gameId);
      ref
          .read(gameControllerProvider(gameId).notifier)
          .replaceState(updatedGame);
      state = GameUiState.empty;
      return updatedGame;
    } on DioException catch (e) {
      state = GameUiState.empty.copyWith(moveError: _extractErrorMessage(e));
    } catch (e) {
      state = GameUiState.empty.copyWith(moveError: 'Unexpected error: $e');
    }

    return null;
  }

  Future<void> _submitMove(
    GameStateModel currentGame,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) async {
    final previousUiState = state;
    final controller = ref.read(gameControllerProvider(gameId).notifier);

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSelection: true,
      clearLegal: true,
    );

    controller.applyOptimisticPlayerMove(
      currentGame,
      fromRow: fromRow,
      fromCol: fromCol,
      toRow: toRow,
      toCol: toCol,
    );

    final request = MoveRequestModel(
      from: [fromRow, fromCol],
      to: [toRow, toCol],
    );

    try {
      final repo = ref.read(gameRepositoryProvider);
      final response = await repo.makeMove(gameId, request);
      controller.applyMoveResponse(response.gameState);
      state = GameUiState.empty;
    } on DioException catch (e) {
      controller.replaceState(currentGame);
      final message = _extractErrorMessage(e);
      state = previousUiState.copyWith(isSubmitting: false, moveError: message);
    } catch (e) {
      controller.replaceState(currentGame);
      state = previousUiState.copyWith(
        isSubmitting: false,
        moveError: 'Unexpected error: $e',
      );
    }
  }

  static String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] as String?;
      if (msg != null && msg.isNotEmpty) {
        return msg;
      }
    }
    return e.message ?? 'Network error';
  }
}

final gameUiProvider = NotifierProvider.autoDispose
    .family<GameUiNotifier, GameUiState, String>(GameUiNotifier.new);
