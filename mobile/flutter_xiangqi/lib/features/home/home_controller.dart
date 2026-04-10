import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/game_persistence_service.dart';
import '../../core/persistence/persistence_providers.dart';
import '../../data/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeState
// ─────────────────────────────────────────────────────────────────────────────

class HomeState {
  /// Non-null only when there is a validated ongoing game to resume.
  final SavedGameSession? resumableSession;

  /// True while the background validation call is in flight.
  final bool isChecking;

  const HomeState({
    this.resumableSession,
    this.isChecking = false,
  });

  HomeState copyWith({
    SavedGameSession? resumableSession,
    bool clearResumable = false,
    bool? isChecking,
  }) {
    return HomeState(
      resumableSession:
          clearResumable ? null : (resumableSession ?? this.resumableSession),
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HomeController
// ─────────────────────────────────────────────────────────────────────────────

class HomeController extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    // 1. Read what's in local storage
    final service = ref.read(gamePersistenceServiceProvider);
    final saved   = await service.loadSession();

    if (saved == null) {
      return const HomeState(); // nothing persisted
    }

    // 2. Validate against the backend
    try {
      final game = await ref.read(gameRepositoryProvider).getGame(saved.gameId);

      if (game.status == 'ongoing') {
        return HomeState(resumableSession: saved);
      } else {
        // Game already finished — wipe local entry
        await service.clearSession();
        return const HomeState();
      }
    } catch (e) {
      // 404 or network error — clear stale entry silently
      debugPrint('[HomeController] Could not validate saved game: $e');
      await service.clearSession();
      return const HomeState();
    }
  }

  /// Call this after the user taps "Continue Game" or if we detect the
  /// game is gone from any other code path.
  Future<void> clearResumable() async {
    final service = ref.read(gamePersistenceServiceProvider);
    await service.clearSession();
    state = AsyncValue.data(
      state.value?.copyWith(clearResumable: true) ?? const HomeState(),
    );
  }

  /// Re-evaluates the saved session (e.g. after returning from a game).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await build());
  }
}

final homeControllerProvider =
    AsyncNotifierProvider<HomeController, HomeState>(HomeController.new);
