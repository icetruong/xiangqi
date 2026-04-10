import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SavedGameSession — minimal data class for a resumable match
// ─────────────────────────────────────────────────────────────────────────────

class SavedGameSession {
  final String gameId;
  final String playerSide;
  final String difficulty;
  final DateTime savedAt;

  const SavedGameSession({
    required this.gameId,
    required this.playerSide,
    required this.difficulty,
    required this.savedAt,
  });

  @override
  String toString() =>
      'SavedGameSession(gameId=$gameId, side=$playerSide, diff=$difficulty)';
}

// ─────────────────────────────────────────────────────────────────────────────
// GamePersistenceService — single-responsibility, no Flutter widget coupling
// ─────────────────────────────────────────────────────────────────────────────

class GamePersistenceService {
  static const _keyGameId      = 'last_game_id';
  static const _keySide        = 'last_player_side';
  static const _keyDifficulty  = 'last_difficulty';
  static const _keySavedAt     = 'last_game_saved_at';

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> saveSession(SavedGameSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGameId,     session.gameId);
    await prefs.setString(_keySide,       session.playerSide);
    await prefs.setString(_keyDifficulty, session.difficulty);
    await prefs.setString(_keySavedAt,    session.savedAt.toIso8601String());
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  Future<SavedGameSession?> loadSession() async {
    try {
      final prefs  = await SharedPreferences.getInstance();
      final gameId = prefs.getString(_keyGameId);
      if (gameId == null || gameId.isEmpty) return null;

      final side       = prefs.getString(_keySide)       ?? 'r';
      final difficulty = prefs.getString(_keyDifficulty)  ?? 'normal';
      final savedAtRaw = prefs.getString(_keySavedAt);
      final savedAt    = savedAtRaw != null
          ? DateTime.tryParse(savedAtRaw) ?? DateTime.now()
          : DateTime.now();

      return SavedGameSession(
        gameId:     gameId,
        playerSide: side,
        difficulty: difficulty,
        savedAt:    savedAt,
      );
    } catch (_) {
      // Corrupted prefs — treat as no session
      return null;
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyGameId);
    await prefs.remove(_keySide);
    await prefs.remove(_keyDifficulty);
    await prefs.remove(_keySavedAt);
  }
}
