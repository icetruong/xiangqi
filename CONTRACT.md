# 📋 Xiangqi PvE — Data Contract (Nguồn chân lý)

> **Mục đích**: Định nghĩa chính xác format dữ liệu giữa UI ↔ API ↔ Engine.  
> **Quy tắc**: Tất cả code phải tuân thủ contract này. Thay đổi contract phải update file này trước.

---

## 1️⃣ Board State Format

### 1.1 Cấu trúc
- **Type**: JSON Array 2D
- **Kích thước**: `10 rows × 9 columns` (index 0-based)
- **Chiều**: `[row][col]`
  - Row 0 = phía trên (đen)
  - Row 9 = phía dưới (đỏ)
  - Col 0 = trái, Col 8 = phải

### 1.2 Ô cờ (Cell)
- **Ô trống**: `""` (chuỗi rỗng)
- **Có quân**: `"<color><type>"` (2-3 ký tự)

### 1.3 Piece Code Format
**Cấu trúc**: `<color><type>`

#### Colors:
- `r` = Red (Đỏ) — Người chơi mặc định
- `b` = Black (Đen) — AI mặc định

#### Types:
| Code | Tên tiếng Anh | Tên tiếng Việt | Unicode |
|------|---------------|----------------|---------|
| `K`  | King          | Tướng          | ♔/♚     |
| `A`  | Advisor       | Sĩ             | ♕/♛     |
| `E`  | Elephant      | Tượng          | ♗/♝     |
| `H`  | Horse         | Mã             | ♘/♞     |
| `R`  | Rook/Chariot  | Xe             | ♖/♜     |
| `C`  | Cannon        | Pháo           | ♗/♝     |
| `P`  | Pawn/Soldier  | Tốt/Binh       | ♙/♟     |

#### Ví dụ Piece Codes:
- `rK` = Red King (Tướng đỏ)
- `bR` = Black Rook (Xe đen)
- `rP` = Red Pawn (Binh đỏ)
- `bC` = Black Cannon (Pháo đen)

### 1.4 Board State Example (Initial Position)
```json
[
  ["bR", "bH", "bE", "bA", "bK", "bA", "bE", "bH", "bR"],
  ["",   "",   "",   "",   "",   "",   "",   "",   ""],
  ["",   "bC", "",   "",   "",   "",   "",   "bC", ""],
  ["bP", "",   "bP", "",   "bP", "",   "bP", "",   "bP"],
  ["",   "",   "",   "",   "",   "",   "",   "",   ""],
  ["",   "",   "",   "",   "",   "",   "",   "",   ""],
  ["rP", "",   "rP", "",   "rP", "",   "rP", "",   "rP"],
  ["",   "rC", "",   "",   "",   "",   "",   "rC", ""],
  ["",   "",   "",   "",   "",   "",   "",   "",   ""],
  ["rR", "rH", "rE", "rA", "rK", "rA", "rE", "rH", "rR"]
]
```

### 1.5 Validation Rules
- ✅ Phải là array 10 phần tử
- ✅ Mỗi row phải là array 9 phần tử
- ✅ Mỗi cell phải là string
- ✅ Cell không trống phải match pattern: `^[rb][KAEHRCP]$`
- ❌ Không cho phép piece codes không hợp lệ

---

## 2️⃣ Move Format

### 2.1 Client → Server (Request)
```json
{
  "from": [row, col],
  "to": [row, col]
}
```

#### Example:
```json
{
  "from": [9, 4],
  "to": [8, 4]
}
```
→ Di chuyển quân ở vị trí (9,4) đến (8,4)

### 2.2 Validation Rules
- ✅ `from` và `to` phải là array có đúng 2 phần tử
- ✅ Mỗi phần tử phải là integer
- ✅ Row: `0 ≤ row ≤ 9`
- ✅ Col: `0 ≤ col ≤ 8`
- ✅ `from ≠ to`
- ✅ Ô `from` phải có quân của player

---

## 3️⃣ API Response Format

### 3.1 Success Response (ok=true)
```json
{
  "ok": true,
  "board_state": [[...10x9 array...]],
  "current_turn": "r" | "b",
  "status": "ongoing" | "finished",
  "winner": "r" | "b" | "draw" | null,
  "end_reason": "checkmate" | "stalemate" | "resign" | "timeout" | "draw" | null,
  "last_move": {
    "from": [row, col],
    "to": [row, col],
    "piece": "rP",
    "captured": "bH" | null
  } | null
}
```

#### Field Descriptions:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ok` | boolean | ✅ | `true` nếu thành công |
| `board_state` | array | ✅ | Trạng thái bàn cờ hiện tại (10x9) |
| `current_turn` | string | ✅ | Lượt của ai: `"r"` hoặc `"b"` |
| `status` | string | ✅ | `"ongoing"` hoặc `"finished"` |
| `winner` | string/null | ✅ | `"r"`, `"b"`, `"draw"`, hoặc `null` |
| `end_reason` | string/null | ✅ | Lý do kết thúc (nếu finished) |
| `last_move` | object/null | ✅ | Thông tin nước đi cuối (null nếu init) |

#### End Reasons:
- `"checkmate"` — Chiếu hết
- `"stalemate"` — Bí quân (không có nước hợp lệ nhưng không bị chiếu)
- `"resign"` — Đầu hàng
- `"timeout"` — Hết giờ (nếu có time control)
- `"draw"` — Hòa (theo luật hoặc thỏa thuận)

### 3.2 Error Response (ok=false)
```json
{
  "ok": false,
  "error_code": "ERROR_CODE",
  "message": "Human-readable error message",
  "details": {} | null
}
```

#### Field Descriptions:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ok` | boolean | ✅ | Luôn `false` |
| `error_code` | string | ✅ | Mã lỗi chuẩn (xem mục 4) |
| `message` | string | ✅ | Thông báo lỗi cho người dùng |
| `details` | object/null | ⚪ | Thông tin bổ sung (optional) |

---

## 4️⃣ Error Codes

### 4.1 Standard Error Codes

| Code | HTTP Status | Meaning | Example Message |
|------|-------------|---------|-----------------|
| `BAD_REQUEST` | 400 | Request format sai | "Invalid JSON format" |
| `INVALID_MOVE` | 400 | Nước đi không hợp lệ theo luật | "Knight cannot move to that square" |
| `GAME_NOT_FOUND` | 404 | Game ID không tồn tại | "Game {id} not found" |
| `GAME_FINISHED` | 400 | Ván đã kết thúc | "Cannot move, game already finished" |
| `NOT_YOUR_TURN` | 400 | Sai lượt | "It's AI's turn, please wait" |
| `INVALID_PIECE` | 400 | Chọn quân sai màu | "You can only move red pieces" |
| `EMPTY_SQUARE` | 400 | Ô xuất phát trống | "No piece at position [9,4]" |
| `SERVER_ERROR` | 500 | Lỗi nội bộ server | "Internal server error" |

### 4.2 Error Response Examples

#### Example 1: Invalid Move
```json
{
  "ok": false,
  "error_code": "INVALID_MOVE",
  "message": "Pawn cannot move backwards",
  "details": {
    "from": [6, 0],
    "to": [7, 0],
    "piece": "rP"
  }
}
```

#### Example 2: Not Your Turn
```json
{
  "ok": false,
  "error_code": "NOT_YOUR_TURN",
  "message": "It's black's turn (AI is thinking)",
  "details": {
    "current_turn": "b"
  }
}
```

#### Example 3: Game Finished
```json
{
  "ok": false,
  "error_code": "GAME_FINISHED",
  "message": "Cannot move, game already finished",
  "details": {
    "status": "finished",
    "winner": "b",
    "end_reason": "checkmate"
  }
}
```

---

## 5️⃣ API Endpoints Contract

### 5.1 Create Game
**Endpoint**: `POST /api/games/`

#### Request Body:
```json
{
  "difficulty": "easy" | "normal" | "hard",
  "player_side": "r" | "b"  // optional, default "r"
}
```

#### Success Response (201 Created):
```json
{
  "ok": true,
  "game_id": "550e8400-e29b-41d4-a716-446655440000",
  "board_state": [[...initial position...]],
  "current_turn": "r",
  "status": "ongoing",
  "winner": null,
  "end_reason": null,
  "last_move": null,
  "difficulty": "easy",
  "player_side": "r",
  "ai_side": "b"
}
```

---

### 5.2 Get Game State
**Endpoint**: `GET /api/games/<game_id>/`

#### Success Response (200 OK):
```json
{
  "ok": true,
  "game_id": "550e8400-e29b-41d4-a716-446655440000",
  "board_state": [[...]],
  "current_turn": "r",
  "status": "ongoing",
  "winner": null,
  "end_reason": null,
  "last_move": {...},
  "difficulty": "easy",
  "player_side": "r",
  "ai_side": "b",
  "created_at": "2026-02-12T08:00:00Z",
  "updated_at": "2026-02-12T08:05:00Z"
}
```

#### Error Response (404):
```json
{
  "ok": false,
  "error_code": "GAME_NOT_FOUND",
  "message": "Game 550e8400-... not found"
}
```

---

### 5.3 Apply Move (Core Endpoint)
**Endpoint**: `POST /api/games/<game_id>/move`

#### Request Body:
```json
{
  "from": [9, 4],
  "to": [8, 4]
}
```

#### Success Response (200 OK):
```json
{
  "ok": true,
  "board_state": [[...updated state after AI move...]],
  "current_turn": "r",
  "status": "ongoing",
  "winner": null,
  "end_reason": null,
  "last_move": {
    "from": [0, 1],
    "to": [2, 2],
    "piece": "bH",
    "captured": null
  }
}
```

> **Lưu ý**: Response luôn chứa state **sau khi AI đã đi** (trừ khi game kết thúc ngay sau nước của player).

#### Error Responses:
- `400 BAD_REQUEST` — Format sai
- `400 INVALID_MOVE` — Nước đi không hợp lệ
- `400 GAME_FINISHED` — Ván đã kết thúc
- `400 NOT_YOUR_TURN` — Sai lượt
- `404 GAME_NOT_FOUND` — Game không tồn tại
- `500 SERVER_ERROR` — Lỗi server

---

### 5.4 Get Legal Moves (Optional)
**Endpoint**: `GET /api/games/<game_id>/legal-moves?from=<row>,<col>`

#### Request:
```
GET /api/games/550e8400-.../legal-moves?from=9,4
```

#### Success Response (200 OK):
```json
{
  "ok": true,
  "from": [9, 4],
  "piece": "rK",
  "legal_moves": [
    [8, 4]
  ]
}
```

#### Use Case:
- Highlight các ô có thể di chuyển khi user click vào một quân

---

## 6️⃣ Engine Adapter Contract

### 6.1 Required Functions

#### Function 1: Initialize Game
```python
def init_game_state() -> list[list[str]]:
    """
    Tạo board state ban đầu (vị trí khởi đầu cờ tướng).
    
    Returns:
        board_state: 10x9 array theo format đã định nghĩa
    """
```

---

#### Function 2: Apply Move
```python
def apply_move(
    board_state: list[list[str]], 
    side: str, 
    move: dict
) -> tuple[list[list[str]], dict]:
    """
    Áp dụng một nước đi lên board state.
    
    Args:
        board_state: State hiện tại (10x9)
        side: "r" hoặc "b"
        move: {"from": [r,c], "to": [r,c]}
    
    Returns:
        (new_state, meta) where:
            new_state: Board state mới sau khi đi
            meta: {
                "piece": "rP",
                "captured": "bH" hoặc None,
                "is_check": bool,  # optional
                "is_checkmate": bool  # optional
            }
    
    Raises:
        ValueError: Nếu move không hợp lệ
    """
```

---

#### Function 3: Check Endgame
```python
def check_endgame(
    board_state: list[list[str]], 
    side_to_move: str
) -> tuple[str, str | None, str | None]:
    """
    Kiểm tra game đã kết thúc chưa.
    
    Args:
        board_state: State hiện tại (10x9)
        side_to_move: "r" hoặc "b" (lượt của ai)
    
    Returns:
        (status, winner, end_reason) where:
            status: "ongoing" | "finished"
            winner: "r" | "b" | "draw" | None
            end_reason: "checkmate" | "stalemate" | "draw" | None
    """
```

---

#### Function 4: Pick AI Move
```python
def pick_ai_move(
    board_state: list[list[str]], 
    ai_side: str, 
    difficulty: str
) -> dict:
    """
    AI chọn nước đi.
    
    Args:
        board_state: State hiện tại (10x9)
        ai_side: "r" hoặc "b"
        difficulty: "easy" | "normal" | "hard"
    
    Returns:
        move: {"from": [r,c], "to": [r,c]}
    
    Raises:
        RuntimeError: Nếu không có nước đi hợp lệ nào
    """
```

---

#### Function 5: List Legal Moves (Optional)
```python
def list_legal_moves(
    board_state: list[list[str]], 
    side: str, 
    from_pos: tuple[int, int] | None = None
) -> list[dict]:
    """
    Liệt kê các nước đi hợp lệ.
    
    Args:
        board_state: State hiện tại (10x9)
        side: "r" hoặc "b"
        from_pos: (row, col) hoặc None
            - Nếu có: chỉ trả moves từ vị trí đó
            - Nếu None: trả tất cả moves hợp lệ
    
    Returns:
        moves: [{"from": [r,c], "to": [r,c]}, ...]
    """
```

---

## 7️⃣ Testing Contract

### 7.1 Unit Test Cases (Engine Adapter)

#### Test 1: Board Initialization
```python
def test_init_board():
    board = init_game_state()
    assert len(board) == 10
    assert len(board[0]) == 9
    assert board[9][4] == "rK"  # Red King
    assert board[0][4] == "bK"  # Black King
```

#### Test 2: Valid Move
```python
def test_apply_valid_move():
    board = init_game_state()
    move = {"from": [9, 4], "to": [8, 4]}
    new_board, meta = apply_move(board, "r", move)
    
    assert new_board[9][4] == ""  # Ô cũ trống
    assert new_board[8][4] == "rK"  # King đã di chuyển
    assert meta["piece"] == "rK"
    assert meta["captured"] is None
```

#### Test 3: Invalid Move
```python
def test_apply_invalid_move():
    board = init_game_state()
    move = {"from": [9, 4], "to": [5, 4]}  # King không đi xa thế này
    
    with pytest.raises(ValueError):
        apply_move(board, "r", move)
```

#### Test 4: Capture Piece
```python
def test_capture():
    # Setup custom board với quân đối phương có thể ăn
    board = custom_board_with_pieces()
    move = {"from": [6, 0], "to": [3, 0]}  # Pawn ăn pawn
    
    new_board, meta = apply_move(board, "r", move)
    assert meta["captured"] == "bP"
```

#### Test 5: Checkmate Detection
```python
def test_checkmate():
    board = setup_checkmate_position()
    status, winner, reason = check_endgame(board, "b")
    
    assert status == "finished"
    assert winner == "r"
    assert reason == "checkmate"
```

---

### 7.2 API Integration Tests

#### Test 1: Create Game
```python
def test_create_game(client):
    response = client.post('/api/games/', json={"difficulty": "easy"})
    data = response.json()
    
    assert response.status_code == 201
    assert data["ok"] is True
    assert "game_id" in data
    assert data["status"] == "ongoing"
```

#### Test 2: Valid Move Flow
```python
def test_player_move_then_ai(client):
    # Create game
    game = create_test_game(client)
    
    # Player move
    response = client.post(f'/api/games/{game["game_id"]}/move', json={
        "from": [9, 4], "to": [8, 4]
    })
    
    data = response.json()
    assert data["ok"] is True
    assert data["current_turn"] == "r"  # Sau AI đi, lại lượt người
    assert data["last_move"]["piece"] == "bH"  # AI vừa đi (ví dụ)
```

#### Test 3: Invalid Move Rejected
```python
def test_invalid_move_rejected(client):
    game = create_test_game(client)
    
    response = client.post(f'/api/games/{game["game_id"]}/move', json={
        "from": [9, 4], "to": [0, 0]  # Nước đi không hợp lệ
    })
    
    data = response.json()
    assert data["ok"] is False
    assert data["error_code"] == "INVALID_MOVE"
```

---

## 8️⃣ Implementation Checklist

### Phase 1: Contract Setup ✅
- [x] Định nghĩa board state format
- [x] Định nghĩa move format
- [x] Định nghĩa response format
- [x] Định nghĩa error codes
- [x] Định nghĩa engine adapter interface

### Phase 2: Engine Adapter
- [ ] Implement `init_game_state()`
- [ ] Implement `apply_move()` với full validation
- [ ] Implement `check_endgame()`
- [ ] Implement `pick_ai_move()` (easy = random)
- [ ] Implement `list_legal_moves()` (optional)
- [ ] Unit tests cho adapter (≥80% coverage)

### Phase 3: Django Backend
- [ ] Model `Game` + migrations
- [ ] Model `Move` (optional)
- [ ] API endpoint: `POST /api/games/`
- [ ] API endpoint: `GET /api/games/<id>/`
- [ ] API endpoint: `POST /api/games/<id>/move`
- [ ] Integration tests

### Phase 4: Frontend
- [ ] Template `/game/<id>/` render board
- [ ] JS: Click to select piece
- [ ] JS: Highlight legal moves
- [ ] JS: Call API + update board
- [ ] Static files (SVG pieces)

---

## 9️⃣ Notes & Edge Cases

### 9.1 AI Turn Handling
- Server **KHÔNG** trả ngay sau nước người chơi
- Server đợi AI chọn + đi xong mới trả response
- Response chứa state **sau khi AI đã đi**

### 9.2 Endgame Flow
```
Player move → check endgame
   ├─ Finished → return (no AI move)
   └─ Ongoing → AI move → check endgame → return
```

### 9.3 Concurrent Requests
- Nếu client spam requests → server phải queue hoặc reject
- Lock game khi đang xử lý move (database transaction)

### 9.4 Time Limits
- AI phải trả move trong < 5s (hard timeout)
- Nếu AI chạy lâu → cần async (Phase 2)

---

## 🔒 Contract Version
- **Version**: 1.0
- **Last Updated**: 2026-02-12
- **Status**: FINAL (cho MVP)

---

**✅ Contract đã hoàn tất. Mọi implementation phải tuân thủ file này.**
