import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_state_model.dart';
import '../../data/providers.dart';

class GameController extends AsyncNotifier<GameStateModel> {
  GameController(this.gameId);

  final String gameId;

  @override
  Future<GameStateModel> build() async {
    return ref.read(gameRepositoryProvider).getGame(gameId);
  }

  Future<void> refreshGame() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(gameRepositoryProvider).getGame(gameId),
    );
  }
}

final gameControllerProvider =
    AsyncNotifierProvider.autoDispose.family<GameController, GameStateModel, String>(
  GameController.new,
);
