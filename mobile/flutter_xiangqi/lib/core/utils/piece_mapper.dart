/// Maps backend piece codes to display information.
///
/// Backend format: two-character string, e.g. "rK", "bR", "rP".
///   • First character: 'r' = red, 'b' = black
///   • Second character: piece type
///
/// Piece type codes (from backend engine):
///   K = King (將/帥)   A = Advisor (士/仕)   E = Elephant (象/相)
///   H = Horse (馬)     R = Rook (車)          C = Cannon (炮)
///   P = Pawn (卒/兵)
class PieceMapper {
  PieceMapper._(); // non-instantiable utility class

  // ── Chinese labels ────────────────────────────────────────────────────────

  /// Returns the Chinese character label for a piece.
  ///
  /// Red pieces use traditional general-side characters (帥, 仕, 相, 馬, 車, 炮, 兵).
  /// Black pieces use counsellor-side characters (將, 士, 象, 馬, 車, 炮, 卒).
  static String chineseLabel(String color, String type) {
    if (color == 'r') {
      return _redLabels[type] ?? type;
    } else {
      return _blackLabels[type] ?? type;
    }
  }

  static const _redLabels = {
    'K': '帥',
    'A': '仕',
    'E': '相',
    'H': '馬',
    'N': '馬',
    'R': '車',
    'C': '炮',
    'P': '兵',
  };

  static const _blackLabels = {
    'K': '將',
    'A': '士',
    'E': '象',
    'H': '馬',
    'N': '馬',
    'R': '車',
    'C': '炮',
    'P': '卒',
  };

  // ── Asset paths ───────────────────────────────────────────────────────────

  /// Returns the asset image path for a piece, or null if assets are not
  /// available.
  ///
  /// Expected asset location: assets/images/pieces/{color}{type}.svg
  /// e.g. assets/images/pieces/bK.svg for black king.
  static String? assetPath(String color, String type) {
    return 'assets/images/pieces/$color$type.svg';
  }


  // ── Convenience helpers ───────────────────────────────────────────────────

  /// Whether image assets are expected to be present.
  ///
  /// Set to false during early development to always show the text fallback.
  static const bool assetsAvailable = true;
}
