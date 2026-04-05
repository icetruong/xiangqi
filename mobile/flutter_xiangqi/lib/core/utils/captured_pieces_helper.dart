import '../../data/models/move_model.dart';

/// Pure utility that derives captured-piece information from [MoveModel] history.
///
/// No widget logic here — widgets receive the [CapturedPieces] value object and
/// render it however they like.
class CapturedPiecesHelper {
  CapturedPiecesHelper._(); // non-instantiable

  /// Returns captured piece lists grouped by the capturing side.
  ///
  /// [capturedByRed] — pieces (type codes like 'bP', 'bR') taken by red.
  /// [capturedByBlack] — pieces (type codes like 'rP', 'rR') taken by black.
  ///
  /// Gracefully skips moves with no [MoveModel.captured] data.
  static CapturedPieces fromHistory(List<MoveModel> history) {
    final capturedByRed = <String>[];
    final capturedByBlack = <String>[];

    for (final move in history) {
      final cap = move.captured;
      if (cap == null || cap.isEmpty) continue;
      final movingSide = move.side;
      if (movingSide == 'r') {
        capturedByRed.add(cap);
      } else if (movingSide == 'b') {
        capturedByBlack.add(cap);
      }
    }

    return CapturedPieces(
      capturedByRed: capturedByRed,
      capturedByBlack: capturedByBlack,
    );
  }
}

/// Simple value object returned by [CapturedPiecesHelper.fromHistory].
class CapturedPieces {
  /// Pieces captured by the red player (opponent's — black — pieces).
  final List<String> capturedByRed;

  /// Pieces captured by the black player (opponent's — red — pieces).
  final List<String> capturedByBlack;

  const CapturedPieces({
    required this.capturedByRed,
    required this.capturedByBlack,
  });

  bool get isEmpty => capturedByRed.isEmpty && capturedByBlack.isEmpty;
}
