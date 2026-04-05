import '../models/rules_section.dart';

const List<RulesSection> xiangqiRulesContent = [
  RulesSection(
    title: 'Bàn cờ & Mục tiêu',
    subtitle: 'Tổng quan về Tướng Kỳ',
    blocks: [
      RuleParagraph('Bàn cờ tướng là một hình chữ nhật gồm 9 đường dọc và 10 đường ngang cắt nhau tạo thành 90 giao điểm. Các quân cờ sẽ được đặt và di chuyển trên các giao điểm này.'),
      RuleParagraph('Ở giữa bàn cờ có một khoảng trống gọi là "Sông" (Hà), chia bàn cờ thành hai phần bằng nhau ứng với lãnh thổ của hai bên.'),
      RuleParagraph('Mỗi bên có một khu vực 3x3 gọi là "Cửu Cung". Tướng và Sĩ không bao giờ được phép rời khỏi Cửu Cung của phe mình.'),
      RuleParagraph('Mục tiêu lớn nhất của trò chơi là "Chiếu bí" (Bắt) được Tướng của đối phương.'),
    ],
  ),
  RulesSection(
    title: 'Quân cờ',
    subtitle: 'Các lực lượng trên bàn cờ',
    blocks: [
      RuleParagraph('Mỗi bên có 16 quân cờ, chia đều thành 7 loại quân, thường được phân biệt bằng màu sắc (Đỏ/Đen) và chữ Hán khắc trên mặt:'),
      RuleBulletList([
        '1 Tướng (Đỏ là Tướng / Đen là Soái)',
        '2 Sĩ (Sĩ / Sĩ)',
        '2 Tượng (Tượng / Ghềnh hoặc Tượng)',
        '2 Mã (Mã)',
        '2 Xe (Xa)',
        '2 Pháo (Pháo)',
        '5 Tốt (Binh / Tốt)',
      ]),
    ],
  ),
  RulesSection(
    title: 'Xếp quân ban đầu',
    subtitle: 'Khởi tạo ván cờ',
    blocks: [
      RuleParagraph('Hai bên ban đầu phân bố quân theo một sơ đồ cố định. Tướng đứng ở chính giữa Cửu cung, tuyến dưới cùng.'),
      RuleParagraph('Hàng sát mép bàn cờ là tuyến phòng thủ chính gồm Tướng, Sĩ, Tượng, Mã, Xe. Phía trên có hàng Pháo và hàng tiền đạo là Tốt chặn các mặt.'),
    ],
  ),
  RulesSection(
    title: 'Xếp quân (chi tiết)',
    subtitle: 'Vị trí từng quân',
    blocks: [
      RuleBulletList([
        'Xe: Đặt ở hai góc bàn cờ (hàng 1, cột 1 và 9).',
        'Mã: Xếp ngay cạnh Xe (cột 2 và 8).',
        'Tượng: Xếp cạnh Mã (cột 3 và 7).',
        'Sĩ: Xếp sát hai bên Tướng (cột 4 và 6).',
        'Tướng: Đứng ở tâm hàng cuối (cột 5).',
        'Pháo: Đứng sau hàng Tốt một bước (hàng 3, cột 2 và 8).',
        'Tốt: Xếp ở hàng 4, nhảy cóc cách nhau 1 ô (cột 1, 3, 5, 7, 9).',
      ]),
    ],
  ),
  RulesSection(
    title: 'Luật đi quân (Phần 1)',
    subtitle: 'Tướng, Sĩ, Tượng, Xe',
    blocks: [
      RuleTable([
        ['Quân', 'Cách đi', 'Giới hạn'],
        ['Tượng', 'Đi chéo 2 ô (chữ Điền)', 'Không qua sông, bị cản nếu có quân ở giữa'],
        ['Sĩ', 'Đi chéo 1 ô', 'Chỉ ở trong Cửu cung'],
        ['Tướng', 'Đi dọc/ngang 1 ô', 'Chỉ ở trong Cửu cung. Hai Tướng không nhìn mặt nhau'],
        ['Xe', 'Ngang dọc tuỳ ý', 'Không bị cản, trừ khi có quân chặn đường'],
      ]),
    ],
  ),
  RulesSection(
    title: 'Luật đi quân (Phần 2)',
    subtitle: 'Pháo, Mã, Tốt',
    blocks: [
      RuleTable([
        ['Quân', 'Cách đi', 'Ăn quân'],
        ['Pháo', 'Đi như Xe', 'Chỉ ăn quân khi nhảy qua đúng 1 quân (ngòi)'],
        ['Mã', 'Đi thẳng 1 chéo 1', 'Bị "cản Mã" nếu có quân sát ở hướng đi thẳng'],
        ['Tốt', 'Đi thẳng tiến 1 ô', 'Khi qua sông được đi ngang, không được lùi'],
      ]),
    ],
  ),
  RulesSection(
    title: 'Ăn quân, Chiếu/Bí',
    subtitle: 'Quy tắc tương tác',
    blocks: [
      RuleParagraph('Khi quân di chuyển đến vị trí của đối phương, quân đối phương bị ăn.'),
      RuleBulletList([
        'Chiếu: Khi nước đi đe dọa ăn Tướng ở lượt sau.',
        'Chiếu bí: Đối phương bị chiếu nhưng không thể giải cứu (hóa giải), bên chiếu thắng.',
        'Lộ mặt tướng: Hai Tướng để trống trên cùng cột dọc là vi phạm luật.',
      ]),
    ],
  ),
  RulesSection(
    title: 'Điều kiện kết thúc / Ghi chú',
    subtitle: 'Thắng, thua, hoà',
    blocks: [
      RuleBulletList([
        'Bắt Tướng (Thắng): Chiếu bí được đối phương.',
        'Hết nước đi (Thua): Đến lượt nhưng không có nước đi hợp lệ.',
        'Phạm luật (Thua): Lặp nước chiếu quá nhiều lần hoặc vi phạm luật liên tục.',
        'Hoà: Khi không bên nào có thể thắng, hoặc hai bên thoả thuận hoà.',
      ]),
    ],
  ),
];
