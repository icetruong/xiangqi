import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game_state_model.dart';
import '../../data/models/move_request_model.dart';
import '../../data/providers.dart';
import 'state/game_ui_state.dart';

/// Loads and refreshes the persisted game state from the backend.
class GameController extends AsyncNotifier<GameStateModel> {
  GameController(this.gameId);

  final String gameId;
  static const Duration _pollInterval = Duration(milliseconds: 650);

  Timer? _pollTimer;
  bool _isPollRequestInFlight = false;

  @override
  Future<GameStateModel> build() async {
    ref.onDispose(_stopPolling);
    return ref.read(gameRepositoryProvider).getGame(gameId);
  }

  Future<void> refreshGame() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(gameRepositoryProvider).getGame(gameId),
    );
  }

  void replaceState(GameStateModel updated) {
    _stopPolling();
    state = AsyncValue.data(updated);
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
    state = AsyncValue.data(updated);

    final aiTurn = updated.status == 'ongoing' &&
        updated.playerSide != null &&
        updated.currentTurn != updated.playerSide;

    debugPrint(
      '[Poll] applyMoveResponse '
      'currentTurn=${updated.currentTurn} '
      'playerSide=${updated.playerSide} '
      'status=${updated.status} '
      'isAiThinking=${updated.isAiThinking} '
      'willPoll=$aiTurn',
    );

    if (aiTurn) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    if (_pollTimer != null && _pollTimer!.isActive) {
      debugPrint('[Poll] Already polling, skipped duplicate start');
      return;
    }

    debugPrint(
      '[Poll] START polling game $gameId every '
      '${_pollInterval.inMilliseconds} ms',
    );

    unawaited(_pollOnce());
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_pollOnce());
    });
  }

  Future<void> _pollOnce() async {
    if (_isPollRequestInFlight) {
      return;
    }

    _isPollRequestInFlight = true;
    try {
      final newState = await ref.read(gameRepositoryProvider).getGame(gameId);
      state = AsyncValue.data(newState);

      debugPrint(
        '[Poll] currentTurn=${newState.currentTurn} '
        'playerSide=${newState.playerSide} '
        'status=${newState.status} '
        'isAiThinking=${newState.isAiThinking}',
      );

      final shouldStop = newState.status != 'ongoing' ||
          (newState.playerSide != null &&
              newState.currentTurn == newState.playerSide);

      if (shouldStop) {
        _stopPolling();
      }
    } catch (e) {
      debugPrint('[Poll] Error during poll: $e');
    } finally {
      _isPollRequestInFlight = false;
    }
  }

  void _stopPolling() {
    debugPrint('[Poll] STOP polling game $gameId');
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPollRequestInFlight = false;
  }
}

final gameControllerProvider = AsyncNotifierProvider.autoDispose.family<
    GameController,
    GameStateModel,
    String>(GameController.new);

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
    if (state.isSubmitting || game.isAiThinking) {
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
      state = previousUiState.copyWith(
        isSubmitting: false,
        moveError: message,
      );
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

final gameUiProvider =
    NotifierProvider.autoDispose.family<GameUiNotifier, GameUiState, String>(
      GameUiNotifier.new,
    );
