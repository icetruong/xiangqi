import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_xiangqi/core/utils/piece_mapper.dart';

void main() {
  group('PieceMapper.chineseLabel', () {
    test('uses side-specific labels for red and black pieces', () {
      expect(PieceMapper.chineseLabel('r', 'K'), '\u5E25');
      expect(PieceMapper.chineseLabel('b', 'K'), '\u5C07');

      expect(PieceMapper.chineseLabel('r', 'A'), '\u4ED5');
      expect(PieceMapper.chineseLabel('b', 'A'), '\u58EB');

      expect(PieceMapper.chineseLabel('r', 'E'), '\u76F8');
      expect(PieceMapper.chineseLabel('b', 'E'), '\u8C61');

      expect(PieceMapper.chineseLabel('r', 'H'), '\u508C');
      expect(PieceMapper.chineseLabel('b', 'H'), '\u99AC');

      expect(PieceMapper.chineseLabel('r', 'R'), '\u4FE5');
      expect(PieceMapper.chineseLabel('b', 'R'), '\u8ECA');

      expect(PieceMapper.chineseLabel('r', 'C'), '\u70AE');
      expect(PieceMapper.chineseLabel('b', 'C'), '\u7832');

      expect(PieceMapper.chineseLabel('r', 'P'), '\u5175');
      expect(PieceMapper.chineseLabel('b', 'P'), '\u5352');
    });

    test('supports N as a horse alias', () {
      expect(PieceMapper.chineseLabel('r', 'N'), '\u508C');
      expect(PieceMapper.chineseLabel('b', 'N'), '\u99AC');
    });
  });

  test('uses a shared token base asset for each side', () {
    expect(PieceMapper.assetPath('r', 'p'), 'assets/images/pieces/rK.svg');
    expect(PieceMapper.assetPath('r', 'h'), 'assets/images/pieces/rK.svg');
    expect(PieceMapper.assetPath('b', 'h'), 'assets/images/pieces/bK.svg');
    expect(PieceMapper.assetPath('b', 'r'), 'assets/images/pieces/bK.svg');
  });
}
