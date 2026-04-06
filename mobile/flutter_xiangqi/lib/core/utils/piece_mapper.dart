/// Maps backend piece codes to display information.
///
/// Backend format: two-character string, e.g. `rK`, `bR`, `rP`.
///   - First character: `r` = red, `b` = black
///   - Second character: piece type
///
/// Piece type codes (from backend engine):
///   - `K` = king/general
///   - `A` = advisor/guard
///   - `E` = elephant/minister
///   - `H`/`N` = horse
///   - `R` = rook
///   - `C` = cannon
///   - `P` = pawn
class PieceMapper {
  PieceMapper._();

  static const Map<String, String> _redLabels = {
    'K': '\u5E25', // shuai
    'A': '\u4ED5', // shi
    'E': '\u76F8', // xiang
    'H': '\u508C', // ma
    'N': '\u508C', // ma
    'R': '\u4FE5', // ju
    'C': '\u70AE', // pao
    'P': '\u5175', // bing
  };

  static const Map<String, String> _blackLabels = {
    'K': '\u5C07', // jiang
    'A': '\u58EB', // shi
    'E': '\u8C61', // xiang
    'H': '\u99AC', // ma
    'N': '\u99AC', // ma
    'R': '\u8ECA', // ju
    'C': '\u7832', // pao
    'P': '\u5352', // zu
  };

  /// Returns the display label for a Xiangqi piece.
  static String chineseLabel(String color, String type) {
    final normalizedType = type.toUpperCase();
    final labels = color == 'r' ? _redLabels : _blackLabels;
    return labels[normalizedType] ?? normalizedType;
  }

  /// Returns the SVG asset path for a piece.
  static String? assetPath(String color, String type) {
    final normalizedType = type.toUpperCase();
    return 'assets/images/pieces/$color$normalizedType.svg';
  }

  /// Whether image assets are expected to be present.
  static const bool assetsAvailable = true;
}
