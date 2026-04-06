import 'piece_model.dart';
import 'move_model.dart';

class GameStateModel {
  final String? gameId;
  final List<List<PieceModel>> boardState;
  final String currentTurn;
  final String status;
  final String? winner;
  final String? endReason;
  final MoveModel? lastMove;
  final String? difficulty;
  final String? playerSide;
  final String? aiSide;
  final String? inCheck;
  final bool isAiThinking;
  final List<MoveModel> moveHistory;
  final List<dynamic>? legalMoves; // Optional listing of legal moves

  GameStateModel({
    this.gameId,
    required this.boardState,
    required this.currentTurn,
    required this.status,
    this.winner,
    this.endReason,
    this.lastMove,
    this.difficulty,
    this.playerSide,
    this.aiSide,
    this.inCheck,
    this.isAiThinking = false,
    this.moveHistory = const [],
    this.legalMoves,
  });

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    final lastMoveJson = json['last_move'] as Map<String, dynamic>?;
    final lastMove =
        lastMoveJson != null ? MoveModel.fromJson(lastMoveJson) : null;
    final moveHistoryJson = json['move_history'] as List<dynamic>?;

    return GameStateModel(
      gameId: json['game_id']?.toString(),
      boardState: (json['board_state'] as List)
          .map(
            (row) => (row as List)
                .map((cell) => PieceModel.fromJson(cell as String))
                .toList(),
          )
          .toList(),
      currentTurn: (json['current_turn'] ?? 'r').toString(),
      status: (json['status'] ?? 'ongoing').toString(),
      winner: json['winner'] as String?,
      endReason: json['end_reason'] as String?,
      lastMove: lastMove,
      difficulty: json['difficulty'] as String?,
      playerSide: json['player_side'] as String?,
      aiSide: json['ai_side'] as String?,
      inCheck: json['in_check'] as String?,
      isAiThinking: json['ai_thinking'] as bool? ?? false,
      moveHistory: moveHistoryJson != null
          ? moveHistoryJson
                .map((move) => MoveModel.fromJson(move as Map<String, dynamic>))
                .toList()
          : lastMove != null
              ? [lastMove]
              : const [],
      legalMoves: json['legal_moves'] as List<dynamic>?,
    );
  }

  String? get id => gameId;
  String get sideToMove => currentTurn;
  List<List<PieceModel>> get board => boardState;
  String? get result => winner;

  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'board_state':
          boardState.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
      'current_turn': currentTurn,
      'status': status,
      'winner': winner,
      'end_reason': endReason,
      'last_move': lastMove?.toJson(),
      'difficulty': difficulty,
      'player_side': playerSide,
      'ai_side': aiSide,
      'in_check': inCheck,
      'ai_thinking': isAiThinking,
      'move_history': moveHistory.map((move) => move.toJson()).toList(),
      'legal_moves': legalMoves,
    };
  }

  GameStateModel optimisticPlayerMove({
    required int fromRow,
    required int fromCol,
    required int toRow,
    required int toCol,
  }) {
    final movingPiece = boardState[fromRow][fromCol];
    if (movingPiece.isEmpty) return this;

    final capturedPiece = boardState[toRow][toCol];
    final nextBoard = boardState
        .map((row) => List<PieceModel>.from(row))
        .toList(growable: false);

    nextBoard[fromRow][fromCol] = PieceModel(code: '');
    nextBoard[toRow][toCol] = movingPiece;

    final nextTurn = aiSide ?? (currentTurn == 'r' ? 'b' : 'r');
    final nextMove = MoveModel(
      from: [fromRow, fromCol],
      to: [toRow, toCol],
      piece: movingPiece.code,
      captured: capturedPiece.isEmpty ? null : capturedPiece.code,
      ply: _nextPly(),
      side: playerSide ?? currentTurn,
    );

    return GameStateModel(
      gameId: gameId,
      boardState: nextBoard,
      currentTurn: nextTurn,
      status: status,
      winner: winner,
      endReason: endReason,
      lastMove: nextMove,
      difficulty: difficulty,
      playerSide: playerSide,
      aiSide: aiSide,
      inCheck: null,
      isAiThinking:
          status == 'ongoing' &&
          playerSide != null &&
          nextTurn != playerSide,
      moveHistory: [...moveHistory, nextMove],
      legalMoves: null,
    );
  }

  int _nextPly() {
    final lastPly = moveHistory.isNotEmpty ? moveHistory.last.ply : null;
    if (lastPly != null) {
      return lastPly + 1;
    }
    return moveHistory.length + 1;
  }
}
