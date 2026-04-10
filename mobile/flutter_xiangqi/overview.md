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
  "player_side": "r"
}
```

Response ví dụ (theo chuẩn `CONTRACT.md`):
```json
{
  "ok": true,
  "game_id": "game_123",
  "board_state": [
    ["bR", "bH", "bE", "bA", "bK", "bA", "bE", "bH", "bR"],
    ["", "", "", "", "", "", "", "", ""],
    ["", "bC", "", "", "", "", "", "bC", ""],
    ["bP", "", "bP", "", "bP", "", "bP", "", "bP"],
    ["", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", ""],
    ["rP", "", "rP", "", "rP", "", "rP", "", "rP"],
    ["", "rC", "", "", "", "", "", "rC", ""],
    ["", "", "", "", "", "", "", "", ""],
    ["rR", "rH", "rE", "rA", "rK", "rA", "rE", "rH", "rR"]
  ],
  "current_turn": "r",
  "status": "ongoing",
  "winner": null,
  "end_reason": null,
  "last_move": null,
  "difficulty": "normal",
  "player_side": "r",
  "ai_side": "b"
}
```

### 7.2 Lấy chi tiết game

`GET /api/games/{id}/`

Response ví dụ:
```json
{
  "ok": true,
  "game_id": "game_123",
  "board_state": [
    ["bR", "bH", "bE", "bA", "bK", "bA", "bE", "bH", "bR"],
    ["", "", "", "", "", "", "", "", ""],
    ["", "bC", "", "", "", "", "", "bC", ""],
    ["bP", "", "bP", "", "bP", "", "bP", "", "bP"],
    ["", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", ""],
    ["rP", "", "rP", "", "rP", "", "rP", "", "rP"],
    ["", "rC", "", "", "", "", "", "rC", ""],
    ["", "", "", "", "", "", "", "", ""],
    ["rR", "rH", "rE", "rA", "rK", "rA", "rE", "rH", "rR"]
  ],
  "current_turn": "b",
  "status": "ongoing",
  "winner": null,
  "end_reason": null,
  "last_move": {
    "from": [6, 4],
    "to": [5, 4],
    "piece": "rP",
    "captured": null
  },
  "legal_moves": [],
  "in_check": null
}
```

### 7.3 Gửi move

`POST /api/games/{id}/move/`

Request ví dụ:
```json
{
  "from": [9, 4],
  "to": [8, 4]
}
```

Response ví dụ:
```json
{
  "ok": true,
  "board_state": [[...]],
  "current_turn": "b",
  "status": "ongoing",
  "winner": null,
  "end_reason": null,
  "last_move": {
    "from": [9, 4],
    "to": [8, 4],
    "piece": "rP",
    "captured": null
  },
  "in_check": null
}
```

### 7.4 Đầu hàng

`POST /api/games/{id}/resign/`

Response ví dụ:
```json
{
  "ok": true,
  "status": "finished",
  "winner": "b",
  "end_reason": "resign"
}
```

### 7.5 Cầu hòa

`POST /api/games/{id}/draw/`

Response ví dụ:
```json
{
  "ok": true,
  "status": "finished",
  "winner": "draw",
  "end_reason": "draw_agreement"
}
```

---

## 8. JSON model tối thiểu

*Lưu ý: Backend trả về `board_state` là mảng 2D (10 hàng x 9 cột) chứa các chuỗi như "rK", "bR", "". Client (Flutter) cần tự parse mảng 2D này thành các `PieceModel` để dễ render.*

### PieceModel (Dùng cho UI, không hứng trực tiếp từ JSON API)
```dart
class PieceModel {
  final String code; // VD: 'K', 'R', 'P'
  final String side; // 'r' hoặc 'b'
  final int row; // 0 đến 9
  final int col; // 0 đến 8

  PieceModel({
    required this.code,
    required this.side,
    required this.row,
    required this.col,
  });
}
```

### GameStateModel
```dart
class GameStateModel {
  final String id;
  final String status;
  final String difficulty;
  final String playerSide;
  final String currentTurn;
  final String? winner;
  final String? endReason;
  late final List<PieceModel> pieces; // Suy ra từ board_state của backend
  final Map<String, dynamic>? lastMove;

  GameStateModel({
    required this.id,
    required this.status,
    required this.difficulty,
    required this.playerSide,
    required this.currentTurn,
    required this.winner,
    required this.endReason,
    required this.pieces,
    this.lastMove,
  });

  // Getter tự tính trạng thái AI
  bool get isAiThinking => currentTurn != playerSide && status == 'ongoing';

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    // Parse mảng 2D board_state thành List<PieceModel>
    final List<PieceModel> parsedPieces = [];
    final boardState = json['board_state'] as List<dynamic>? ?? [];
    
    for (int r = 0; r < boardState.length; r++) {
      final rowItems = boardState[r] as List<dynamic>;
      for (int c = 0; c < rowItems.length; c++) {
        final cell = rowItems[c] as String;
        if (cell.isNotEmpty && cell.length >= 2) {
          parsedPieces.add(PieceModel(
            side: cell[0], // 'r' hoặc 'b'
            code: cell.substring(1), // 'K', 'R', 'P', vv
            row: r,
            col: c,
          ));
        }
      }
    }

    return GameStateModel(
      id: json['game_id'].toString(),
      status: json['status'] ?? 'ongoing',
      difficulty: json['difficulty'] ?? 'normal',
      playerSide: json['player_side'] ?? 'r',
      currentTurn: json['current_turn'] ?? 'r',
      winner: json['winner'],
      endReason: json['end_reason'],
      pieces: parsedPieces,
      lastMove: json['last_move'],
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
    required int fromRow,
    required int fromCol,
    required int toRow,
    required int toCol,
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
- render quân cờ (từ danh sách đã parse từ mảng 2D)
- chọn quân
- đi quân (mảng index row/col hợp lệ)
- hiển thị current turn
- hiển thị trạng thái AI đang nghĩ (khi `currentTurn != playerSide`)
- *(Ghi chú: Move history và Quân bị ăn backend chưa trực tiếp trả danh sách cồng kềnh, client có thể lưu vết via `last_move` hoặc tự giữ nội bộ)*
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
- 9 cột (col 0 -> 8)
- 10 hàng (row 0 -> 9, row 0 là phe đen trên cùng, row 9 là phe đỏ dưới cùng)
- quân nằm trên giao điểm mạng lưới

### Công thức cơ bản
```dart
final cellWidth = boardWidth / 8;
final cellHeight = boardHeight / 9;

// Trục x tương ứng với cột (col), trục y tương ứng với hàng (row)
final left = piece.col * cellWidth - pieceSize / 2;
final top = piece.row * cellHeight - pieceSize / 2;
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
- kiểm tra `gameState.isAiThinking == true` (tức là `currentTurn != playerSide` và `status == 'ongoing'`)
  - bắt đầu poll mỗi 800ms–1000ms
  - mỗi lần poll: gọi `GET /api/games/{id}/`, update `gameState`
  - stop polling khi:
    - `currentTurn == playerSide`
    - hoặc `status == 'finished'`

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

### API / JSON Format
- [ ] xác nhận endpoint create game
- [ ] xác nhận endpoint game detail
- [ ] xác nhận endpoint move
- [ ] hiểu cách map 2D array `board_state` thành object List
- [ ] hiểu logic tự tính `is_ai_thinking` theo `current_turn`
- [ ] hiểu cấu trúc `winner` và `end_reason`

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
15. Add result dialog / resign / draw
16. Refactor UI và polish

## PHASE 8
You are extending an existing Flutter Xiangqi mobile app.

Current goal: PHASE 8 ONLY — Resume Game / Local Persistence.

Context:
- The app is already playable end-to-end
- It supports:
  - create game
  - board rendering
  - move submission
  - AI polling
  - premium web-inspired UI
- There is currently no login/account system
- If the user closes the app, the current game may be lost from the app flow
- The backend remains the source of truth
- We want to store the most recent ongoing game locally and restore it on app relaunch

Main objective:
Implement local resume-game persistence so the user can continue the last ongoing match.

Requirements:

1. Use shared_preferences
- Add a clean local persistence layer
- Do NOT call SharedPreferences directly from widgets everywhere

2. Save minimal local game session info
At minimum persist:
- lastGameId
- playerSide
- difficulty
- timestamp if useful

3. Save state during gameplay
- After creating a new game, store the current game info locally
- After successful move / polling updates, keep the saved game entry current
- If the game ends, clear the saved active-game entry

4. Restore on app launch
- On app startup or home screen init:
  - check if a saved game exists
  - call the backend game detail endpoint
  - if the game is still ongoing:
    - show a clear "Continue Game" action on the home screen
    - or auto-resume if the architecture already supports it cleanly
  - if the game is finished or not found:
    - clear the saved local state

5. Home screen UX
- Add a "Continue Game" button/card if a resumable game exists
- Keep it visually consistent with the current premium Xiangqi theme
- Do not clutter the start screen
- If no resumable game exists, do not show it

6. Navigation behavior
- Tapping "Continue Game" should navigate back into the correct GameScreen using the saved gameId
- Keep current routing architecture intact

7. Architecture requirements
Use a clean modular structure, for example:
lib/
  core/
    persistence/
      game_persistence_service.dart
  features/
    home/
      home_controller.dart or equivalent provider logic
- Keep storage logic separate from UI
- Do not overengineer
- Reuse existing controller/provider patterns

8. Data safety
- Handle cases where:
  - saved gameId is invalid
  - backend returns 404
  - backend says the game is finished
- In those cases, clear local saved state gracefully

9. Keep scope limited
- Do NOT redesign the home screen
- Do NOT change backend contract
- Do NOT add user accounts/login
- Do NOT break current move flow or polling
- Focus only on resume-game persistence and continue-game UX

Files likely to inspect/update:
- pubspec.yaml
- lib/features/home/*
- lib/features/game/*
- lib/core/*
- routing/navigation files

Expected output:
1. Explain the persistence architecture
2. Show which files are created/updated
3. Generate all Flutter code for resume-game support
4. Explain how saved game state is created, restored, and cleared
5. Stop after Phase 8 only

## PHASE 9
You are extending an existing Flutter Xiangqi mobile app.

Current goal: PHASE 8 ONLY — Resume Game / Local Persistence.

Context:
- The app is already playable end-to-end
- It supports:
  - create game
  - board rendering
  - move submission
  - AI polling
  - premium web-inspired UI
- There is currently no login/account system
- If the user closes the app, the current game may be lost from the app flow
- The backend remains the source of truth
- We want to store the most recent ongoing game locally and restore it on app relaunch

Main objective:
Implement local resume-game persistence so the user can continue the last ongoing match.

Requirements:

1. Use shared_preferences
- Add a clean local persistence layer
- Do NOT call SharedPreferences directly from widgets everywhere

2. Save minimal local game session info
At minimum persist:
- lastGameId
- playerSide
- difficulty
- timestamp if useful

3. Save state during gameplay
- After creating a new game, store the current game info locally
- After successful move / polling updates, keep the saved game entry current
- If the game ends, clear the saved active-game entry

4. Restore on app launch
- On app startup or home screen init:
  - check if a saved game exists
  - call the backend game detail endpoint
  - if the game is still ongoing:
    - show a clear "Continue Game" action on the home screen
    - or auto-resume if the architecture already supports it cleanly
  - if the game is finished or not found:
    - clear the saved local state

5. Home screen UX
- Add a "Continue Game" button/card if a resumable game exists
- Keep it visually consistent with the current premium Xiangqi theme
- Do not clutter the start screen
- If no resumable game exists, do not show it

6. Navigation behavior
- Tapping "Continue Game" should navigate back into the correct GameScreen using the saved gameId
- Keep current routing architecture intact

7. Architecture requirements
Use a clean modular structure, for example:
lib/
  core/
    persistence/
      game_persistence_service.dart
  features/
    home/
      home_controller.dart or equivalent provider logic
- Keep storage logic separate from UI
- Do not overengineer
- Reuse existing controller/provider patterns

8. Data safety
- Handle cases where:
  - saved gameId is invalid
  - backend returns 404
  - backend says the game is finished
- In those cases, clear local saved state gracefully

9. Keep scope limited
- Do NOT redesign the home screen
- Do NOT change backend contract
- Do NOT add user accounts/login
- Do NOT break current move flow or polling
- Focus only on resume-game persistence and continue-game UX

Files likely to inspect/update:
- pubspec.yaml
- lib/features/home/*
- lib/features/game/*
- lib/core/*
- routing/navigation files

Expected output:
1. Explain the persistence architecture
2. Show which files are created/updated
3. Generate all Flutter code for resume-game support
4. Explain how saved game state is created, restored, and cleared
5. Stop after Phase 8 only

## PHASE 10
You are extending an existing Flutter Xiangqi mobile app.

Current goal: PHASE 9 ONLY — Audio / Music / Sound Effects.

Context:
- The app is already playable
- There is already a music toggle concept in the UI
- The project already uses or plans to use audioplayers
- We want working sound/music, not just placeholders
- The app has a premium Xiangqi theme, so the audio should enhance atmosphere
- The backend remains unchanged; this is purely client-side UX/audio behavior

Main objective:
Implement background music and sound effects cleanly and reliably.

Requirements:

1. Use a dedicated AudioService
- Do NOT call audioplayers directly from many widgets
- Create a clean service layer for:
  - background music
  - sound effects
  - mute/unmute state
  - optional volume controls if needed later

2. Reuse local assets if available
- Inspect project/repo assets for available music/sfx files
- Prefer reusing existing assets already in the repo
- If exact assets are missing, use clean placeholders but document them

3. Support background music
- Home/start screen music should play or be prepared
- Game screen can continue the same music or use the same background track
- Music should loop
- Music should obey mute/unmute toggle

4. Support sound effects for key events
At minimum:
- piece select
- successful move
- capture
- check
- game over / victory / defeat
Only trigger sounds from real events, not randomly

5. Integrate with existing game flow
- piece select sound on selecting a valid piece
- move sound on successful move
- capture sound if last move indicates captured piece
- check sound when backend state indicates in_check
- result sound when the game ends
- Do not break current move logic or polling

6. Persist audio preference
- Save mute/music enabled state locally using shared_preferences
- On app launch, restore the previous preference

7. Tie into existing UI controls
- The music/settings control in the start screen should actually toggle music state if reasonable
- If it is currently placeholder-only, wire it up cleanly
- Keep the existing premium UI intact

8. Architecture suggestions
Use something like:
lib/
  core/
    audio/
      audio_service.dart
      audio_state.dart
      game_sfx_mapper.dart
- Keep widgets dumb
- Let controller/service handle audio triggering where appropriate

9. Keep scope limited
- Do NOT redesign the whole app
- Do NOT refactor unrelated UI
- Do NOT break current navigation, polling, or board logic
- Focus only on production-worthy music/SFX integration

10. Reliability
- Avoid overlapping chaotic sound playback
- Keep music and SFX channels separated if helpful
- Ensure repeated polling does not spam check/game-over sounds repeatedly
- Only trigger one-time sounds when state changes

Files likely to inspect/update:
- pubspec.yaml
- any existing audio/music widgets
- game controller
- home screen / settings toggle
- core/audio/*

Expected output:
1. Explain the audio architecture
2. List assets reused or assumed
3. Show which files are created/updated
4. Generate all Flutter code for audio/music support
5. Explain the event-to-sound mapping
6. Stop after Phase 9 only


## PHASE 11
You are extending an existing Flutter Xiangqi mobile app.

Current goal: PHASE 12 ONLY — Check Effect and Endgame Result Modal.

Context:
- The app is already playable
- It already supports:
  - move submission
  - AI polling
  - premium web-inspired UI
- The backend already exposes relevant state fields such as:
  - status
  - winner
  - end_reason
  - in_check
  - current_turn
- We want the mobile experience to feel more polished and dramatic, similar in spirit to the web version

Main objectives:
1. Add a polished “chiếu tướng / check” effect
2. Add a premium result modal/screen for:
   - chiến thắng
   - thất bại
   - hòa

PART A — CHECK EFFECT

Requirements:

1. Trigger condition
- Use backend-provided `in_check` as the source of truth
- When `in_check` is not null:
  - determine which side is currently in check
  - locate that side’s general/king piece on the board
  - render the effect there

2. Visual style
- Match the premium Xiangqi theme
- Avoid generic error banners
- Preferred effect:
  - animated red/orange glow or ring around the checked general
  - subtle pulse animation
  - optional compact warning text such as:
    - "Chiếu tướng!"
    - "Tướng đang bị chiếu!"
- Keep it dramatic but elegant

3. Placement
- Main visual effect should be attached to the checked general on the board
- Optional text warning can appear inline near the top or near the board, but must not be blocking

4. Animation behavior
- Start when a checked state appears
- Continue while the state remains checked
- Stop cleanly when `in_check` becomes null

PART B — RESULT MODAL / SCREEN

Requirements:

1. Trigger condition
- When backend state indicates the game is finished
- Use:
  - status
  - winner
  - end_reason
- Do not guess outcome outside backend truth

2. Outcome mapping
Derive player-facing result:
- if winner == player_side -> victory
- if winner == ai_side -> defeat
- if draw / draw_agreement / equivalent -> draw
Map end_reason into clean Vietnamese copy

3. Visual style
- Must feel premium and web-inspired
- Do NOT use a default Material AlertDialog
- Use a custom styled modal/panel with:
  - dark dimmed background
  - centered premium panel
  - elegant serif typography
  - gold / ivory / red / dark-brown palette
  - optional decorative elements matching current app style

4. Result content
Show:
- main title:
  - "Chiến thắng"
  - "Thất bại"
  - "Hòa"
- short subtitle or reason
- optional explanation from end_reason
- action buttons:
  - Chơi lại
  - Về trang chính
Optional:
- Xem lại ván / Đóng if architecture already supports it cleanly

5. Behavior
- Show result modal only once per finished game state
- Do not reopen repeatedly on rebuild
- Keep navigation clean
- Chơi lại:
  - start a new game with same side/difficulty if available
  - or navigate cleanly into the new-game flow
- Về trang chính:
  - return to home screen

PART C — ARCHITECTURE REQUIREMENTS

1. Keep logic clean
- Backend state remains source of truth
- Do not place all logic inside GameScreen build
- Use helpers/widgets/view-models where appropriate

2. Suggested structure
lib/
  features/
    game/
      widgets/
        check_effect_overlay.dart
        check_warning_banner.dart
        game_result_modal.dart
        result_action_button.dart
      models/
        game_result_view_model.dart
      utils/
        board_piece_locator.dart

3. Avoid regressions
- Do NOT break polling
- Do NOT break move animation
- Do NOT break board rendering
- Keep styling consistent with the rest of the app

Files likely to inspect/update:
- game controller
- game screen
- board widget
- result modal widgets
- state/view models
- theme/shared styled components

Expected output:
1. Explain how `in_check` is detected and rendered
2. Explain how endgame result is mapped from backend fields
3. Show which files are created/updated
4. Generate all Flutter code for the check effect and result modal
5. Mention assumptions about possible end_reason values
6. Stop after Phase 10 only