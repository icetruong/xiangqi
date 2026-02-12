# Django Xiangqi (Cờ tướng) Web PvE (Người vs AI) — Tài liệu tổng thể (1 file)

> Mục tiêu: làm web cho người chơi đánh với AI, nhanh – chắc – dễ debug.  
> Kiến trúc: **Django Monolith** (Templates + API nhẹ + JS/HTMX), **server-authoritative**.

---

## 0) Mục tiêu & phạm vi (MVP)
### MVP phải có
- Tạo ván mới (new game)
- Trang web hiển thị bàn cờ `/game/<id>/`
- Người đi 1 nước → Server validate → AI đi 1 nước → trả state mới
- Lưu state trong DB (ít nhất Game)
- Kết thúc ván: status + winner + end_reason
- Invalid move bị chặn rõ ràng (error_code)

### Không làm ngay (để sau)
- PvP realtime (WebSocket/Channels)
- Spectator / Chat
- Rating / matchmaking
- AI async (Celery/RQ) nếu AI chạy lâu

---

## 1) Hướng triển khai nên làm (tối ưu nhanh + chắc)
### Kiến trúc: Django Monolith
- **Django Templates**: render trang `/game/<id>/`
- **API nhẹ (JSON)**: create/get/move (+ optional legal-moves)
- **JS/HTMX**: xử lý click/select, gọi API, cập nhật board

### Vì sao hợp nhất cho PvE
- PvE turn-based → **không cần WebSocket** giai đoạn đầu
- Logic game + AI ở server → **khó gian lận**, dễ debug
- Ít công nghệ phụ → ra MVP nhanh

---

## 2) Nguyên tắc quan trọng (server-authoritative)
- Client **KHÔNG** được gửi “board_state mới”.
- Client chỉ gửi **move** (`from/to`).
- Server:
  1) load state từ DB
  2) validate + apply move bằng engine
  3) gọi AI chọn move + apply
  4) lưu DB
  5) trả state mới

---

## 3) Contract dữ liệu (chuẩn hoá từ đầu)
> Đây là “giao kèo” giữa UI ↔ API ↔ Engine. Làm xong phần này trước để khỏi loạn.

### 3.1 Board State (nguồn sự thật)
- `board_state`: JSON array **10x9**
- ô trống: `""`
- quân: string mã quân theo chuẩn:
  - prefix màu: `r` (đỏ) / `b` (đen)
  - type: `K,A,E,R,N,C,P`
  - ví dụ: `rK`, `bR`, `rP`, ...

### 3.2 Move format (client → server)
```json
{ "from": [row, col], "to": [row, col] }
3.3 Response chuẩn (server → client)
{
  "ok": true,
  "board_state": [[...10x9...]],
  "current_turn": "r|b",
  "status": "ongoing|finished",
  "winner": "r|b|draw|null",
  "end_reason": "checkmate|resign|timeout|draw|null",
  "last_move": {
    "from": [r,c],
    "to": [r,c],
    "piece": "rP",
    "captured": "bN|null"
  }
}
3.4 Error contract (cần thống nhất)
Response lỗi:

{ "ok": false, "error_code": "INVALID_MOVE", "message": "..." }
Danh sách đề xuất:

BAD_REQUEST (format sai)

INVALID_MOVE (luật không cho)

GAME_FINISHED (ván đã kết thúc)

NOT_YOUR_TURN (sai lượt)

SERVER_ERROR (lỗi nội bộ)

4) Tổ chức project (mapping với repo của bạn)
4.1 Giữ engine/ là core library
Không để Django phụ thuộc logic console/UI trong engine

Django chỉ gọi adapter/service “bọc” engine

4.2 Django apps tối thiểu
games/ (core cho PvE)

accounts/ (optional nếu cần login)

4.3 Folder gợi ý trong games/
models.py (Game, Move)

services/engine_adapter.py (interface gọi engine)

services/game_service.py (flow: player move + ai move)

api_views.py (API JSON)

views.py (render template)

templates/games/game.html (UI)

5) Adapter Engine (việc QUAN TRỌNG NHẤT)
Nếu adapter ổn thì Django/UI chỉ là “vỏ”.

5.1 Interface tối thiểu (Python thuần)
init_game_state() -> board_state

list_legal_moves(board_state, side, from=None) -> moves (optional)

apply_move(board_state, side, move) -> (new_state, meta)

check_endgame(board_state, side_to_move) -> (status, winner, reason)

pick_ai_move(board_state, ai_side, difficulty) -> move

5.2 Trách nhiệm của adapter
Validate board_state đúng 10x9

Validate piece codes hợp lệ

Validate move from/to trong range

Chuyển đổi nếu engine dùng object Board/Move nội bộ

6) Database Models (MVP)
6.1 Model: Game (bắt buộc)
id

status: ongoing | finished

board_state (JSON)

current_turn: "r" | "b"

player_side: mặc định "r"

ai_side: mặc định "b"

difficulty: easy|normal|hard

winner: "r"|"b"|"draw"|null

end_reason: nullable

timestamps

6.2 Model: Move (khuyến nghị)
game FK

ply (0..n)

side ("r"/"b")

from_row/from_col/to_row/to_col

piece, captured (nullable)

timestamps

Nếu muốn ra MVP nhanh hơn: có thể làm Game-only trước, Move làm sau.

7) API Endpoints (nhẹ, đủ chạy)
7.1 Create game
POST /api/games/

input: { "difficulty": "easy|normal|hard" }

output: { "game_id": "...", ...state }

7.2 Get game state
GET /api/games/<id>/

output: ...state

7.3 Apply player move (core)
POST /api/games/<id>/move

input: { "from":[r,c], "to":[r,c] }

server flow:

load Game + state

check status != finished

check đúng lượt người

apply move người bằng adapter

check endgame; nếu xong → save + return

pick AI move (sync) → apply

check endgame → save + return state

7.4 (Optional) Legal moves for highlight
GET /api/games/<id>/legal-moves?from=[r,c]

output: list các to hợp lệ

8) Trang web UI (Templates + JS/HTMX)
8.1 Route
GET /game/<id>/ render game.html

8.2 UI responsibilities
Render grid 10x9 từ board_state

Map piece code -> SVG/PNG icon

Click flow:

click quân (chỉ cho chọn quân của player_side)

click ô đích

call API move

render board theo response

8.3 Nâng cấp UI (không bắt buộc)
Highlight last move

Highlight legal moves

Move history sidebar

Button restart/new game

9) AI (sync trước, nâng cấp sau)
9.1 Difficulty gợi ý
easy: random legal move

normal: greedy (ưu tiên ăn quân có giá trị cao)

hard: minimax depth thấp (nếu engine hỗ trợ)

9.2 Khi nào cần async
AI chạy > 1–2s:

dùng Celery/RQ

API trả “AI thinking…”

khi xong update state (giai đoạn sau)

10) Testing tối thiểu (để không vỡ luật)
10.1 Engine/adapter tests
state 10x9 validate

invalid move bị reject

apply move ra state đúng

endgame detection đúng

10.2 API tests
create game trả state đúng

move valid: ok=true, state đổi

move invalid: ok=false + error_code

finished game: chặn move tiếp

11) Thứ tự làm (roadmap chuẩn, không mắc kẹt)
Đây là “hướng để làm trước” theo đúng ưu tiên.

Phase 1 — Core trước (quan trọng nhất)
Chốt contract (move/state/response/error_code) trong chính file này (mục 3)

Làm engine_adapter chạy được bằng Python thuần:

init/apply/check_endgame/pick_ai

Tạo Django project + app games

Phase 2 — API trước UI
Model Game + endpoint POST /api/games/ + GET /api/games/<id>/

Endpoint core POST /api/games/<id>/move (người → AI)

Phase 3 — UI (lúc này làm rất nhanh)
Template /game/<id>/ render board

JS click-to-move gọi API + update board

Phase 4 — Nâng cấp
Move history / legal-moves highlight

Tối ưu AI / async nếu cần

Auth, deploy, polish UI

12) Definition of Done (MVP)
Tạo ván → hiển thị bàn cờ đúng

Người đi hợp lệ → AI đi → board update đúng

Invalid move bị chặn rõ ràng (error_code)

Ván kết thúc có status/winner, không cho đi tiếp

State lưu DB ổn định

