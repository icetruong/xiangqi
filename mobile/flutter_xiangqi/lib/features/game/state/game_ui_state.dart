/// Immutable UI state for the game screen.
///
/// Tracks transient interaction data that is NOT part of the persisted
/// backend game state ([GameStateModel]).  Kept separate so that the board
/// state and the UI state can evolve independently.
class GameUiState {
  /// Row index of the currently-selected piece (null = nothing selected).
  final int? selectedRow;

  /// Column index of the currently-selected piece (null = nothing selected).
  final int? selectedCol;

  /// True while a POST /move request is in-flight.
  final bool isSubmitting;

  /// Non-null when the last move was rejected or a network error occurred.
  /// Cleared on the next successful interaction.
  final String? moveError;

  /// Legal move destinations (each entry is `[row, col]`) for the selected
  /// piece, pre-filtered from the backend's `legal_moves` list.
  ///
  /// Null when:
  ///   • no piece is selected, or
  ///   • the backend returned no legal_moves data (graceful degradation).
  final List<List<int>>? legalMovesForSelected;

  const GameUiState({
    this.selectedRow,
    this.selectedCol,
    this.isSubmitting = false,
    this.moveError,
    this.legalMovesForSelected,
  });

  /// No piece is selected.
  static const empty = GameUiState();

  bool get hasSelection => selectedRow != null && selectedCol != null;

  /// Returns a copy with changed fields.
  GameUiState copyWith({
    int? selectedRow,
    int? selectedCol,
    bool clearSelection = false,
    bool? isSubmitting,
    String? moveError,
    bool clearError = false,
    List<List<int>>? legalMovesForSelected,
    bool clearLegal = false,
  }) {
    return GameUiState(
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      moveError: clearError ? null : (moveError ?? this.moveError),
      legalMovesForSelected:
          clearSelection || clearLegal ? null : (legalMovesForSelected ?? this.legalMovesForSelected),
    );
  }
}
