enum GameActionType { resign, draw, exit }

extension GameActionTypeCopy on GameActionType {
  String get label => switch (this) {
    GameActionType.resign => 'Nhận thua',
    GameActionType.draw => 'Cầu hòa',
    GameActionType.exit => 'Thoát',
  };

  String get seal => switch (this) {
    GameActionType.resign => '印',
    GameActionType.draw => '和',
    GameActionType.exit => '退',
  };

  String get confirmTitle => switch (this) {
    GameActionType.resign => 'Xác nhận nhận thua?',
    GameActionType.draw => 'Gửi yêu cầu hòa?',
    GameActionType.exit => 'Xác nhận rời ván?',
  };

  String get confirmBody => switch (this) {
    GameActionType.resign =>
      'Một khi nhận thua, ván cờ sẽ khép lại ngay và AI sẽ giành chiến thắng.',
    GameActionType.draw =>
      'Cầu hòa sẽ khép lại trận đấu với kết quả hòa trong chế độ đối đầu AI hiện tại.',
    GameActionType.exit => 'Bạn sẽ rời bàn cờ hiện tại và quay về sảnh chính.',
  };

  String get confirmDetail => switch (this) {
    GameActionType.resign => 'Kết quả sẽ được ghi là bại do nhận thua.',
    GameActionType.draw => 'Kết quả sẽ được ghi là hòa thỏa thuận.',
    GameActionType.exit => 'Bạn có thể tạo ván mới lại từ màn hình chính.',
  };

  String get confirmLabel => switch (this) {
    GameActionType.resign => 'Xác nhận',
    GameActionType.draw => 'Gửi yêu cầu',
    GameActionType.exit => 'Thoát',
  };

  String get cancelLabel => switch (this) {
    GameActionType.exit => 'Ở lại',
    _ => 'Hủy',
  };

  String get eyebrow => switch (this) {
    GameActionType.resign => 'Ritual Of Resign',
    GameActionType.draw => 'Treaty Of Peace',
    GameActionType.exit => 'Withdraw From Battle',
  };

  String get shortHint => switch (this) {
    GameActionType.resign => 'Kết thúc ván với thất bại',
    GameActionType.draw => 'Khép lại trận đấu với hòa cục',
    GameActionType.exit => 'Rời bàn cờ và trở về sảnh',
  };
}
