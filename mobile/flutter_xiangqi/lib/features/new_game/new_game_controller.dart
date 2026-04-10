import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/persistence/game_persistence_service.dart';
import '../../core/persistence/persistence_providers.dart';
import '../../data/models/game_state_model.dart';
import '../../data/providers.dart';

class NewGameState {
  final String difficulty;
  final String playerSide;
  final AsyncValue<GameStateModel?> creationState;

  NewGameState({
    this.difficulty = 'normal',
    this.playerSide = 'r',
    this.creationState = const AsyncValue.data(null),
  });

  NewGameState copyWith({
    String? difficulty,
    String? playerSide,
    AsyncValue<GameStateModel?>? creationState,
  }) {
    return NewGameState(
      difficulty: difficulty ?? this.difficulty,
      playerSide: playerSide ?? this.playerSide,
      creationState: creationState ?? this.creationState,
    );
  }
}

class NewGameController extends Notifier<NewGameState> {
  @override
  NewGameState build() {
    return NewGameState();
  }

  void setDifficulty(String diff) {
    state = state.copyWith(difficulty: diff);
  }

  void setPlayerSide(String side) {
    state = state.copyWith(playerSide: side);
  }

  Future<GameStateModel?> createGame() async {
    state = state.copyWith(creationState: const AsyncValue.loading());
    try {
      final repo   = ref.read(gameRepositoryProvider);
      final result = await repo.createGame(state.difficulty, state.playerSide);

      // ── Persist session so resumption works after app restart ──
      if (result.gameId != null) {
        final service = ref.read(gamePersistenceServiceProvider);
        await service.saveSession(
          SavedGameSession(
            gameId:     result.gameId!,
            playerSide: result.playerSide ?? state.playerSide,
            difficulty: result.difficulty ?? state.difficulty,
            savedAt:    DateTime.now(),
          ),
        );
      }

      state = state.copyWith(creationState: AsyncValue.data(result));
      return result;
    } catch (e, st) {
      state = state.copyWith(creationState: AsyncValue.error(e, st));
      return null;
    }
  }
}

final newGameControllerProvider =
    NotifierProvider.autoDispose<NewGameController, NewGameState>(
  NewGameController.new,
);

