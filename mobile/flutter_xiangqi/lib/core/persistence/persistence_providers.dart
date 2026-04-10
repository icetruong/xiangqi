import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_persistence_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Singleton service provider
// ─────────────────────────────────────────────────────────────────────────────

final gamePersistenceServiceProvider = Provider<GamePersistenceService>(
  (ref) => GamePersistenceService(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Eager session loader — used on startup so the HomeController can await it
// ─────────────────────────────────────────────────────────────────────────────

final savedGameSessionProvider = FutureProvider<SavedGameSession?>(
  (ref) {
    final service = ref.watch(gamePersistenceServiceProvider);
    return service.loadSession();
  },
);
