import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_state_model.dart';
import '../../data/models/move_request_model.dart';
import '../../data/providers.dart';
import 'state/game_ui_state.dart';

// ── Backend game state ────────────────────────────────────────────────────────

/// Loads and refreshes the [GameStateModel] from the backend.
///
/// This notifier owns only the *persisted* game state; transient UI state
/// (selection, submission, errors) lives in [GameUiNotifier].
class GameController extends AsyncNotifier<GameStateModel> {
  GameController(this.gameId);

  final String gameId;
  Timer? _pollTimer;

  @override
  Future<GameStateModel> build() async {
    ref.onDispose(() {
      _stopPolling();
    });
    return ref.read(gameRepositoryProvider).getGame(gameId);
  }

  Future<void> refreshGame() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(gameRepositoryProvider).getGame(gameId),
    );
  }

  /// Applies the updated game state returned by the move endpoint.
  ///
  /// Starts polling when it is now the AI's turn (status ongoing and
  /// currentTurn != playerSide).  This works even if [isAiThinking] is
  /// momentarily false because the backend hasn't flipped the flag yet.
  void applyMoveResponse(GameStateModel updated) {
    state = AsyncValue.data(updated);

    final aiTurn = updated.status == 'ongoing' &&
        updated.playerSide != null &&
        updated.currentTurn != updated.playerSide;

    debugPrint('[Poll] applyMoveResponse — '
        'currentTurn=${updated.currentTurn} '
        'playerSide=${updated.playerSide} '
        'status=${updated.status} '
        'isAiThinking=${updated.isAiThinking} '
        'willPoll=$aiTurn');

    if (aiTurn) {
      _startPolling();
    }
  }

  void _startPolling() {
    if (_pollTimer != null && _pollTimer!.isActive) {
      debugPrint('[Poll] Already polling — skipped duplicate start');
      return;
    }

    debugPrint('[Poll] ▶ START polling game $gameId every 1 s');

    _pollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      debugPrint('[Poll] ↻ Tick #${timer.tick} — calling getGame($gameId)');
      try {
        final newState = await ref.read(gameRepositoryProvider).getGame(gameId);
        state = AsyncValue.data(newState);

        debugPrint('[Poll] ↳ currentTurn=${newState.currentTurn} '
            'playerSide=${newState.playerSide} '
            'status=${newState.status} '
            'isAiThinking=${newState.isAiThinking}');

        // Stop when the game is over OR it is the player's turn again.
        final shouldStop = newState.status != 'ongoing' ||
            (newState.playerSide != null &&
                newState.currentTurn == newState.playerSide);

        if (shouldStop) {
          _stopPolling();
        }
      } catch (e) {
        debugPrint('[Poll] ⚠ Error during poll: $e');
        // Keep polling — transient network errors should not abort the loop.
      }
    });
  }

  void _stopPolling() {
    debugPrint('[Poll] ■ STOP polling game $gameId');
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}

final gameControllerProvider =
    AsyncNotifierProvider.autoDispose.family<GameController, GameStateModel, String>(
  GameController.new,
);

// ── UI interaction state ──────────────────────────────────────────────────────

/// Manages piece selection, move submission, and transient error messages.
///
/// Separated from [GameController] so that UI interactions do not
/// invalidate the async game-state stream unnecessarily.
class GameUiNotifier extends Notifier<GameUiState> {
  GameUiNotifier(this.gameId);

  final String gameId;

  @override
  GameUiState build() => GameUiState.empty;

  // ── Public API used by GameScreen ─────────────────────────────────────────

  /// Selects the piece at [row],[col] and pre-filters its legal destinations.
  ///
  /// Ownership check is done in [tapIntersection]; this method is called
  /// only when the caller has already confirmed the piece belongs to the
  /// current player.
  ///
  /// [game] is needed to access backend-provided [GameStateModel.legalMoves]
  /// for the legal-moves overlay.  Gracefully handles null / missing data.
  void selectPiece(int row, int col, GameStateModel game) {
    final filtered = _filterLegalMovesFor(row, col, game.legalMoves);
    state = GameUiState(
      selectedRow: row,
      selectedCol: col,
      moveError: null,
      legalMovesForSelected: filtered,
    );
  }

  /// Extracts the [toRow, toCol] destinations from [legalMoves] that start
  /// from ([fromRow], [fromCol]).  Returns null when data is unavailable.
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
      // Unexpected format — degrade gracefully.
      return null;
    }
  }

  /// Clears any active selection.
  void clearSelection() {
    state = GameUiState.empty;
  }

  /// Main tap handler called by [XiangqiBoard] for every board intersection.
  ///
  /// Decision logic:
  ///   1. Ignore taps while a move is being submitted.
  ///   2. If tapping the already-selected piece → deselect.
  ///   3. If tapping another own piece → reselect.
  ///   4. If a piece is selected and the tap is elsewhere → submit move.
  ///   5. If nothing is selected and tap is on an empty square → no-op.
  Future<void> tapIntersection(int row, int col, GameStateModel game) async {
    // 1. Ignore during in-flight request.
    if (state.isSubmitting) return;

    // 2. Ignore while AI is computing its reply.
    if (game.isAiThinking) return;

    final piece = game.boardState[row][col];
    final isOwnPiece = !piece.isEmpty && piece.color == game.currentTurn;

    if (!state.hasSelection) {
      // No active selection: only selecting own pieces makes sense.
      if (isOwnPiece) {
        selectPiece(row, col, game);
      }
      return;
    }

    // A piece is already selected:
    if (row == state.selectedRow && col == state.selectedCol) {
      // 2. Tap same square → deselect.
      clearSelection();
      return;
    }

    if (isOwnPiece) {
      // 3. Tap another own piece → reselect.
      selectPiece(row, col, game);
      return;
    }

    // 4. Tap elsewhere → attempt move submission.
    await _submitMove(state.selectedRow!, state.selectedCol!, row, col);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _submitMove(int fromRow, int fromCol, int toRow, int toCol) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final request = MoveRequestModel(
      from: [fromRow, fromCol],
      to: [toRow, toCol],
    );

    try {
      final repo = ref.read(gameRepositoryProvider);
      final response = await repo.makeMove(gameId, request);

      // Assumption: on success, MoveResponseModel.gameState contains the
      // full updated board. GameController is updated directly.
      ref
          .read(gameControllerProvider(gameId).notifier)
          .applyMoveResponse(response.gameState);

      // Clear selection on success.
      state = GameUiState.empty;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      state = GameUiState(moveError: message);
    } catch (e) {
      state = GameUiState(moveError: 'Unexpected error: $e');
    }
  }

  static String _extractErrorMessage(DioException e) {
    // Try to parse the backend's {"ok": false, "message": "..."} payload.
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    }
    return e.message ?? 'Network error';
  }
}

final gameUiProvider =
    NotifierProvider.autoDispose.family<GameUiNotifier, GameUiState, String>(
  GameUiNotifier.new,
);
