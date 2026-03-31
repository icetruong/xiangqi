# Xiangqi Mobile App (Flutter) for Django Backend

## 1. Mục tiêu

Xây dựng app mobile Flutter cho game cờ tướng (Xiangqi) dựa trên backend Django hiện có.

### Kiến trúc tổng quát
- Backend Django giữ nguyên:
  - game rules
  - move validation
  - game persistence
  - AI engine
  - REST API
- Flutter app chỉ là client:
  - hiển thị UI mobile
  - render bàn cờ
  - gửi nước đi
  - poll trạng thái game sau khi AI đánh
  - hiển thị lịch sử, kết quả, quân bị ăn

### Nguyên tắc quan trọng
- Không port engine sang Dart ở giai đoạn đầu
- Không viết lại luật cờ trong Flutter
- Flutter không tự quyết định nước đi hợp lệ
- Toàn bộ validation chính nằm ở backend Django
- Flutter chỉ phản ánh state từ server

---

## 2. Bối cảnh dự án backend hiện tại

Dự án backend hiện tại có cấu trúc logic như sau:

- `games/`: web UI, API, lưu trữ game
- `engine/`: luật cờ, AI, kiểm tra hợp lệ
- `tests/`: test engine và adapter
- `games/services/engine_adapter.py`: cầu nối giữa Django và engine
- `games/services/game_service.py`: tạo game, xử lý move, AI worker
- `games/api_views.py`: REST API cho frontend/client

### AI backend
AI hiện chạy bất đồng bộ:
- sau khi user đi nước, API có thể trả response ngay
- AI được kích hoạt bằng worker thread
- client cần gọi lại endpoint chi tiết game để lấy nước đi mới nhất của AI

### Tài liệu backend phải dùng
Trước khi code app Flutter, luôn đọc:
- `CONTRACT.md`
- `docs/state_format.md`

Hai file này là nguồn chuẩn cho:
- API contract
- JSON schema
- board state format

---

## 3. Mục tiêu chức năng của app Flutter

### Bản v1 cần có
- tạo ván mới
- chọn độ khó
- chọn phe đỏ / đen
- load game state
- hiển thị bàn cờ
- hiển thị quân cờ đúng vị trí
- chạm chọn quân
- chạm đích để đi quân
- gửi move lên backend
- poll lại state khi AI đang nghĩ
- hiển thị kết quả thắng / thua / hòa
- hiển thị lịch sử nước đi
- hiển thị quân bị ăn
- có loading / retry / error state

### Bản v1 chưa cần
- multiplayer
- offline mode
- local engine trong app
- drag & drop nâng cao
- animation phức tạp
- push notification

---

## 4. Cấu trúc thư mục Flutter đề xuất

Đặt app Flutter trong repo hiện tại:

```txt
mobile/flutter_xiangqi/

Cấu trúc trong Flutter:

mobile/flutter_xiangqi/
  lib/
    main.dart
    app/
      app.dart
      router.dart
      theme.dart
    core/
      constants/
        app_constants.dart
        api_constants.dart
      network/
        api_client.dart
        dio_provider.dart
      utils/
        board_utils.dart
        result.dart
    data/
      models/
        game_state_model.dart
        piece_model.dart
        move_request_model.dart
        move_history_item_model.dart
      services/
        game_api_service.dart
      repositories/
        game_repository.dart
        game_repository_impl.dart
    features/
      home/
        home_screen.dart
      new_game/
        new_game_screen.dart
        new_game_controller.dart
      game/
        game_screen.dart
        game_controller.dart
        widgets/
          xiangqi_board.dart
          piece_widget.dart
          move_history_panel.dart
          captured_pieces_panel.dart
          game_status_banner.dart
      settings/
        settings_screen.dart
    shared/
      widgets/
        app_button.dart
        app_loading.dart
        app_error_view.dart
  assets/
    images/
      board.png
      pieces/
        red_king.png
        red_advisor.png
        red_elephant.png
        red_horse.png
        red_rook.png
        red_cannon.png
        red_pawn.png
        black_king.png
        black_advisor.png
        black_elephant.png
        black_horse.png
        black_rook.png
        black_cannon.png
        black_pawn.png
  pubspec.yaml
```

---

## 5. Stack kỹ thuật đề xuất

### Packages bắt buộc
```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.0.0
  flutter_riverpod: ^2.0.0
  go_router: ^14.0.0
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.8.0
```

### Có thể thêm sau
```yaml
dependencies:
  freezed_annotation: ^2.4.0

dev_dependencies:
  freezed: ^2.5.0
```

### Gợi ý
- **State management**: riverpod
- **Routing**: go_router
- **Networking**: dio
- **JSON**: json_serializable
- **Render board**: Stack + Positioned ở giai đoạn đầu

---

## 6. Nguyên tắc code

### Kiến trúc

Tách rõ:
- **data**: models, api, repository
- **features**: UI + controller
- **core**: constants, utils, network
- Không để UI gọi Dio trực tiếp
- Tất cả request đi qua repository

### Rule
- UI không được hardcode game logic
- Chỉ dùng game state từ API
- Không tự tính nước hợp lệ trừ khi backend cung cấp danh sách candidate moves
- Nếu contract backend thay đổi, update model trước rồi mới update UI

---

## 7. API contract kỳ vọng

Cần đối chiếu với `CONTRACT.md` và `docs/state_format.md`.

### 7.1 Tạo game

`POST /api/games/`

Request ví dụ:
```json
{
  "difficulty": "normal",
  "player_side": "red"
}
```

Response ví dụ:
```json
{
  "id": "game_123",
  "status": "playing",
  "difficulty": "normal",
  "player_side": "red",
  "side_to_move": "red",
  "board": [],
  "move_history": [],
  "captured_red": [],
  "captured_black": [],
  "is_ai_thinking": false,
  "result": null
}
```

### 7.2 Lấy chi tiết game

`GET /api/games/{id}/`

Response ví dụ:
```json
{
  "id": "game_123",
  "status": "playing",
  "difficulty": "normal",
  "player_side": "red",
  "side_to_move": "black",
  "board": [
    {
      "piece": "rook",
      "side": "black",
      "x": 0,
      "y": 0
    }
  ],
  "move_history": [],
  "captured_red": [],
  "captured_black": [],
  "is_ai_thinking": true,
  "result": null
}
```

### 7.3 Gửi move

`POST /api/games/{id}/move/`

Request ví dụ:
```json
{
  "from_x": 0,
  "from_y": 6,
  "to_x": 0,
  "to_y": 5
}
```

Response ví dụ:
```json
{
  "ok": true,
  "game": {
    "id": "game_123",
    "status": "playing",
    "player_side": "red",
    "side_to_move": "black",
    "board": [],
    "move_history": [],
    "captured_red": [],
    "captured_black": [],
    "is_ai_thinking": true,
    "result": null
  },
  "message": "Move accepted"
}
```

### 7.4 Đầu hàng

`POST /api/games/{id}/resign/`

Response ví dụ:
```json
{
  "ok": true,
  "status": "finished",
  "result": "loss"
}
```

### 7.5 Cầu hòa

`POST /api/games/{id}/draw/`

*Response tùy contract thật của backend.*

---

## 8. JSON model tối thiểu

### PieceModel
```dart
class PieceModel {
  final String piece;
  final String side;
  final int x;
  final int y;

  PieceModel({
    required this.piece,
    required this.side,
    required this.x,
    required this.y,
  });

  factory PieceModel.fromJson(Map<String, dynamic> json) {
    return PieceModel(
      piece: json['piece'],
      side: json['side'],
      x: json['x'],
      y: json['y'],
    );
  }
}
```

### GameStateModel
```dart
class GameStateModel {
  final String id;
  final String status;
  final String difficulty;
  final String playerSide;
  final String sideToMove;
  final bool isAiThinking;
  final String? result;
  final List<PieceModel> board;
  final List<dynamic> moveHistory;
  final List<dynamic> capturedRed;
  final List<dynamic> capturedBlack;

  GameStateModel({
    required this.id,
    required this.status,
    required this.difficulty,
    required this.playerSide,
    required this.sideToMove,
    required this.isAiThinking,
    required this.result,
    required this.board,
    required this.moveHistory,
    required this.capturedRed,
    required this.capturedBlack,
  });

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    return GameStateModel(
      id: json['id'].toString(),
      status: json['status'],
      difficulty: json['difficulty'] ?? 'normal',
      playerSide: json['player_side'] ?? 'red',
      sideToMove: json['side_to_move'],
      isAiThinking: json['is_ai_thinking'] ?? false,
      result: json['result'],
      board: (json['board'] as List? ?? [])
          .map((e) => PieceModel.fromJson(e))
          .toList(),
      moveHistory: (json['move_history'] as List? ?? []),
      capturedRed: (json['captured_red'] as List? ?? []),
      capturedBlack: (json['captured_black'] as List? ?? []),
    );
  }
}
```

---

## 9. Repository contract

```dart
abstract class GameRepository {
  Future<GameStateModel> createGame({
    required String difficulty,
    required String playerSide,
  });

  Future<GameStateModel> getGame(String gameId);

  Future<GameStateModel> makeMove({
    required String gameId,
    required int fromX,
    required int fromY,
    required int toX,
    required int toY,
  });

  Future<void> resign(String gameId);

  Future<void> requestDraw(String gameId);
}
```

---

## 10. Màn hình cần làm

### 10.1 HomeScreen

Chức năng:
- nút Start New Game
- nút Continue (nếu có game gần nhất)
- nút Settings

### 10.2 NewGameScreen

Chức năng:
- chọn difficulty: easy, normal, hard
- chọn màu: red, black
- nút Start

Flow:
- khi bấm Start:
  - gọi `createGame`
  - nhận `gameId`
  - chuyển sang `GameScreen`

### 10.3 GameScreen

Chức năng:
- render bàn cờ
- render quân cờ
- chọn quân
- đi quân
- hiển thị side to move
- hiển thị trạng thái AI đang nghĩ
- hiển thị move history
- hiển thị quân bị ăn
- nút resign / draw / refresh

### 10.4 Result Dialog

Chức năng:
- hiển thị thắng / thua / hòa
- nút chơi lại
- nút về trang chủ

---

## 11. Cách render bàn cờ

### Giai đoạn đầu

Dùng:
- `AspectRatio`
- `Stack`
- `Positioned`

### Tọa độ bàn cờ

Cờ tướng có:
- 9 cột
- 10 hàng
- quân nằm trên giao điểm

### Công thức cơ bản
```dart
final cellWidth = boardWidth / 8;
final cellHeight = boardHeight / 9;

final left = piece.x * cellWidth - pieceSize / 2;
final top = piece.y * cellHeight - pieceSize / 2;
```

### Lưu ý
- quân đặt theo giao điểm
- không đặt theo trung tâm ô vuông như chess
- cần căn giữa `PieceWidget` theo giao điểm

---

## 12. Tương tác chạm

### Bản v1

Dùng tap-to-move, không drag-drop.

Flow:
1. user chạm vào quân của mình
2. app lưu `selectedPiece`
3. user chạm vị trí đích
4. app gọi API move
5. backend validate
6. app update state

### State local trong GameScreen
- `selectedPiece`
- `isSubmittingMove`
- `errorMessage`
- `pollingTimer`
- `gameState`

---

## 13. Polling AI

### Lý do

AI backend đang chạy bất đồng bộ, nên sau khi player move xong:
- server có thể trả state trung gian
- AI chưa đi ngay trong response
- app phải poll game detail

### Rule polling

Sau khi move thành công:
- nếu `is_ai_thinking == true`
  - bắt đầu poll mỗi 800ms–1000ms
  - mỗi lần poll: gọi `GET /api/games/{id}/`, update `gameState`
  - stop polling khi:
    - `is_ai_thinking == false`
    - hoặc `side_to_move == player_side`
    - hoặc `status == finished`

### Lưu ý
- stop timer ở `dispose`
- tránh tạo nhiều timer chồng nhau
- chỉ có 1 polling session tại một thời điểm

---

## 14. Xử lý lỗi

### Phải có
- network timeout
- server 400 move invalid
- server 404 game not found
- server 500
- mất mạng

### UI kỳ vọng
- loading spinner khi tạo game
- loading overlay khi gửi move
- banner hoặc snackbar khi lỗi
- nút retry khi load game thất bại

---

## 15. Quản lý assets

### Bắt buộc

Thêm vào `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/images/pieces/
```

### Khuyến nghị
- 1 ảnh background bàn cờ
- 14 ảnh quân cờ: 7 loại quân đỏ, 7 loại quân đen

Tên file nên ổn định:
- `red_king.png`
- `red_advisor.png`
- `red_elephant.png`
- `red_horse.png`
- `red_rook.png`
- `red_cannon.png`
- `red_pawn.png`
- `black_king.png`
- `black_advisor.png`
- `black_elephant.png`
- `black_horse.png`
- `black_rook.png`
- `black_cannon.png`
- `black_pawn.png`

---

## 16. Cấu hình network

### ApiConstants
```dart
class ApiConstants {
  static const String baseUrl = 'https://your-railway-domain.up.railway.app';
  static const String apiPrefix = '/api';
}
```

### ApiClient
- dùng `dio`
- set timeout
- set content-type json
- log request/response ở debug mode

### Lưu ý CORS
Với mobile app chạy native:
- thường không bị CORS như web
- nhưng backend vẫn cần config host/domain đúng
- nếu có auth/session, cần xem thêm CSRF/session handling

---

## 17. Quy trình phát triển

### Phase 1 — Khóa contract
- đọc `CONTRACT.md`
- đọc `docs/state_format.md`
- test endpoint bằng Postman
- xác nhận JSON thật của từng endpoint

### Phase 2 — App skeleton
- tạo Flutter app
- cài packages
- setup router
- setup Riverpod
- setup Dio
- tạo models

### Phase 3 — Kết nối API
- create game
- get game detail
- hiển thị JSON raw ở GameScreen

### Phase 4 — Board UI
- dựng board background
- render pieces từ `board[]`
- hiển thị side to move

### Phase 5 — Move handling
- chọn quân
- chọn đích
- gọi move API
- refresh state

### Phase 6 — AI sync
- thêm polling
- thêm loading state
- thêm stop condition

### Phase 7 — Hoàn thiện UX
- move history
- captured pieces
- result dialog
- resign
- draw
- retry / empty state

### Phase 8 — Release
- test máy thật
- build APK/AAB
- chuẩn bị icon, splash, signing

---

## 18. Checklist công việc chi tiết

### Backend
- [ ] xác nhận endpoint create game
- [ ] xác nhận endpoint game detail
- [ ] xác nhận endpoint move
- [ ] xác nhận JSON response thật
- [ ] xác nhận field `is_ai_thinking`
- [ ] xác nhận field `status`
- [ ] xác nhận field `result`
- [ ] xác nhận format `board`

### Flutter foundation
- [ ] setup packages
- [ ] setup router
- [ ] setup theme
- [ ] setup api client
- [ ] setup repository

### New Game flow
- [ ] NewGameScreen
- [ ] chọn difficulty
- [ ] chọn player side
- [ ] create game
- [ ] navigate GameScreen

### Game flow
- [ ] render board
- [ ] render pieces
- [ ] select piece
- [ ] select destination
- [ ] call move API
- [ ] update game state
- [ ] poll AI
- [ ] stop poll đúng lúc

### UX
- [ ] move history
- [ ] captured pieces
- [ ] result dialog
- [ ] resign
- [ ] draw
- [ ] retry button
- [ ] loading state
- [ ] error banner

---

## 19. Definition of Done

Một bản v1 được xem là hoàn thành khi:
- app tạo được game mới từ backend
- app load được state của game
- app render được bàn cờ và quân cờ
- user đi được nước từ mobile
- backend xử lý AI và app sync lại được
- app hiển thị được kết quả cuối ván
- app chạy ổn trên Android device thật

---

## 20. Những lỗi thường gặp cần tránh
- hardcode logic nước đi trong Flutter
- tự đảo trục x/y sai khi render board
- dùng nhiều timer polling chồng nhau
- quên stop timer khi dispose
- cập nhật UI trước khi server trả state thật
- không xử lý invalid move từ backend
- không đọc `CONTRACT.md` mà đoán field JSON
- nhảy vào làm UI đẹp trước khi connect API thành công

---

## 21. Thứ tự code khuyến nghị cho AI IDE

AI IDE phải làm đúng thứ tự sau:

1. Tạo cấu trúc thư mục Flutter như mục 4
2. Cài packages như mục 5
3. Tạo `ApiConstants`, `ApiClient`
4. Tạo `PieceModel`, `GameStateModel`
5. Tạo `GameRepository`
6. Tạo `HomeScreen`
7. Tạo `NewGameScreen`
8. Connect `createGame`
9. Tạo `GameScreen` hiển thị dữ liệu text
10. Render board bằng `Stack` + `Positioned`
11. Render pieces theo tọa độ
12. Implement select piece / select destination
13. Connect move API
14. Implement AI polling
15. Add move history / captured pieces / result dialog
16. Refactor UI và polish