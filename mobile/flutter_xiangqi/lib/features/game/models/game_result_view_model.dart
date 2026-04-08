import '../../../data/models/game_state_model.dart';

enum GameResultOutcome { victory, defeat, draw }

class GameResultViewModel {
  final GameResultOutcome outcome;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String description;
  final String reasonLabel;
  final String hanzi;
  final String seal;

  const GameResultViewModel({
    required this.outcome,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.reasonLabel,
    required this.hanzi,
    required this.seal,
  });

  factory GameResultViewModel.fromGame(GameStateModel game) {
    final playerSide = game.playerSide == 'b' ? 'b' : 'r';
    final outcome = _deriveOutcome(game, playerSide);
    final endReason = game.endReason;

    return GameResultViewModel(
      outcome: outcome,
      eyebrow: 'KET QUA VAN DAU',
      title: switch (outcome) {
        GameResultOutcome.victory => 'Chiến thắng',
        GameResultOutcome.defeat => 'Thất bại',
        GameResultOutcome.draw => 'Hòa',
      },
      subtitle: _subtitleFor(outcome, endReason),
      description: _descriptionFor(outcome, endReason),
      reasonLabel: _reasonLabelFor(outcome, endReason),
      hanzi: switch (outcome) {
        GameResultOutcome.victory => '勝',
        GameResultOutcome.defeat => '敗',
        GameResultOutcome.draw => '和',
      },
      seal: switch (outcome) {
        GameResultOutcome.victory => 'THANG',
        GameResultOutcome.defeat => 'BAI',
        GameResultOutcome.draw => 'HOA',
      },
    );
  }

  static const Set<String> _drawReasons = {
    'draw_agreement',
    'repetition',
    'perpetual_check',
    'insufficient_material',
    'mutual_timeout',
  };

  static GameResultOutcome _deriveOutcome(
    GameStateModel game,
    String playerSide,
  ) {
    if (game.winner == 'draw' || _drawReasons.contains(game.endReason)) {
      return GameResultOutcome.draw;
    }
    if (game.winner == playerSide) {
      return GameResultOutcome.victory;
    }
    if (game.winner == null && game.status == 'finished') {
      return GameResultOutcome.draw;
    }
    return GameResultOutcome.defeat;
  }

  static String _subtitleFor(GameResultOutcome outcome, String? endReason) {
    return switch (outcome) {
      GameResultOutcome.victory => switch (endReason) {
        'checkmate' => 'Bạn đã chiếu bí đối thủ',
        'stalemate' => 'Đối thủ đã hết nước đi',
        'resign' => 'Đối thủ đã chấp nhận thất bại',
        'timeout' => 'Đối thủ đã cạn thời gian',
        'disconnect' => 'Đối thủ rời khỏi ván đấu',
        _ => 'Bạn đã khép lại ván cờ với ưu thế quyết định',
      },
      GameResultOutcome.defeat => switch (endReason) {
        'checkmate' => 'Bạn đã bị chiếu bí',
        'stalemate' => 'Bạn không còn nước đi hợp lệ',
        'resign' => 'Bạn đã nhận thua',
        'timeout' => 'Bạn đã hết thời gian',
        'disconnect' => 'Ván đấu kết thúc do ngắt kết nối',
        _ => 'Thế trận đã nghiêng về phía đối thủ',
      },
      GameResultOutcome.draw => switch (endReason) {
        'draw_agreement' => 'Hai bên chấp thuận hòa cục',
        'repetition' => 'Ván cờ lặp lại thế trận',
        'perpetual_check' => 'Thế cờ kéo dài không thể phân thắng bại',
        'insufficient_material' => 'Không còn đủ lực lượng để kết thúc ván',
        'mutual_timeout' => 'Cả hai bên đều cạn thời gian',
        _ => 'Ván đấu khép lại mà không phân định thắng thua',
      },
    };
  }

  static String _descriptionFor(GameResultOutcome outcome, String? endReason) {
    return switch (outcome) {
      GameResultOutcome.victory => switch (endReason) {
        'checkmate' =>
          'Cung tướng đối phương đã bị phong kín. Bạn có thể mở ngay một ván mới với cùng cấu hình hiện tại.',
        'resign' =>
          'Áp lực bạn tạo ra đã buộc đối thủ đầu hàng trước khi trận chiến kéo dài thêm.',
        _ =>
          'Nhịp độ điều quân và kiểm soát trung lộ đã giúp bạn chốt hạ ván cờ một cách gọn gàng.',
      },
      GameResultOutcome.defeat => switch (endReason) {
        'checkmate' =>
          'Đối thủ đã khai thác được điểm yếu trong cung tướng. Hãy xem lại thế cờ rồi tái đấu ngay.',
        'resign' =>
          'Ván đấu đã khép lại theo lựa chọn của bạn. Bạn vẫn có thể bắt đầu trận mới ngay lập tức.',
        _ =>
          'Ván cờ này chưa đi theo ý muốn, nhưng bố cục và nhịp trận vẫn còn rất đáng để xem lại.',
      },
      GameResultOutcome.draw =>
        'Thế cờ dừng lại trong cân bằng. Bạn có thể giữ lại vị trí này để quan sát thêm hoặc khởi động một ván khác.',
    };
  }

  static String _reasonLabelFor(GameResultOutcome outcome, String? endReason) {
    switch (endReason) {
      case 'checkmate':
        return 'Chiếu bí';
      case 'stalemate':
        return 'Hết nước đi';
      case 'resign':
        return 'Nhận thua';
      case 'draw_agreement':
        return 'Hòa thỏa thuận';
      case 'timeout':
        return 'Hết thời gian';
      case 'disconnect':
        return 'Ngắt kết nối';
      case 'repetition':
        return 'Lặp thế cờ';
      case 'perpetual_check':
        return 'Chiếu dai';
      case 'insufficient_material':
        return 'Thiếu lực lượng';
      case 'mutual_timeout':
        return 'Song phương cạn giờ';
      default:
        return switch (outcome) {
          GameResultOutcome.victory => 'Toàn thắng',
          GameResultOutcome.defeat => 'Cục diện khép lại',
          GameResultOutcome.draw => 'Hòa cục',
        };
    }
  }
}
