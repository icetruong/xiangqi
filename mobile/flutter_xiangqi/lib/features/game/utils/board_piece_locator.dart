import '../../../data/models/piece_model.dart';

class BoardPieceLocation {
  final int row;
  final int col;
  final PieceModel piece;

  const BoardPieceLocation({
    required this.row,
    required this.col,
    required this.piece,
  });
}

class BoardPieceLocator {
  const BoardPieceLocator._();

  static BoardPieceLocation? findCheckedGeneral(
    List<List<PieceModel>> boardState,
    String? checkedSide,
  ) {
    if (checkedSide != 'r' && checkedSide != 'b') {
      return null;
    }

    for (var row = 0; row < boardState.length; row++) {
      final rowList = boardState[row];
      for (var col = 0; col < rowList.length; col++) {
        final piece = rowList[col];
        if (piece.isEmpty || piece.color != checkedSide) {
          continue;
        }
        if (piece.type?.toUpperCase() == 'K') {
          return BoardPieceLocation(row: row, col: col, piece: piece);
        }
      }
    }

    return null;
  }
}
