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
```

### 3.3 Response chuẩn (server → client)
```json
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
```

### 3.4 Error contract (cần thống nhất)
Response lỗi:
```json
{ "ok": false, "error_code": "INVALID_MOVE", "message": "..." }
```

Danh sách error codes:
- `BAD_REQUEST` — Format sai
- `INVALID_MOVE` — Luật không cho
- `GAME_FINISHED` — Ván đã kết thúc
- `NOT_YOUR_TURN` — Sai lượt
- `SERVER_ERROR` — Lỗi nội bộ

## 4) Tổ chức project (mapping với repo của bạn)
### 4.1 Giữ engine/ là core library
- Không để Django phụ thuộc logic console/UI trong engine
- Django chỉ gọi adapter/service "bọc" engine

### 4.2 Django apps tối thiểu
- `games/` — Core cho PvE
- `accounts/` — Optional nếu cần login

### 4.3 Folder gợi ý trong games/
```
games/
├── models.py              # Game, Move models
├── services/
│   ├── engine_adapter.py  # Interface gọi engine
│   └── game_service.py    # Flow: player move + AI move
├── api_views.py           # API JSON endpoints
├── views.py               # Render templates
├── templates/games/
│   └── game.html          # UI bàn cờ
└── static/games/
    ├── css/
    ├── js/
    └── pieces/            # SVG/PNG quân cờ
```

---


## 5) Adapter Engine (việc QUAN TRỌNG NHẤT)
Nếu adapter ổn thì Django/UI chỉ là "vỏ".

### 5.1 Interface tối thiểu (Python thuần)
```python
init_game_state() -> board_state
list_legal_moves(board_state, side, from=None) -> moves  # optional
apply_move(board_state, side, move) -> (new_state, meta)
check_endgame(board_state, side_to_move) -> (status, winner, reason)
pick_ai_move(board_state, ai_side, difficulty) -> move
```

### 5.2 Trách nhiệm của adapter
- Validate board_state đúng 10x9
- Validate piece codes hợp lệ
- Validate move from/to trong range
- Chuyển đổi nếu engine dùng object Board/Move nội bộ

---


## 6) Database Models (MVP)
### 6.1 Model: Game (bắt buộc)
```python
class Game(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    status = models.CharField(max_length=20)  # ongoing | finished
    board_state = models.JSONField()  # 10x9 array
    current_turn = models.CharField(max_length=1)  # r | b
    player_side = models.CharField(max_length=1, default='r')
    ai_side = models.CharField(max_length=1, default='b')
    difficulty = models.CharField(max_length=20)  # easy|normal|hard
    winner = models.CharField(max_length=10, null=True, blank=True)
    end_reason = models.CharField(max_length=50, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

### 6.2 Model: Move (khuyến nghị)
```python
class Move(models.Model):
    game = models.ForeignKey(Game, on_delete=models.CASCADE)
    ply = models.IntegerField()  # 0..n
    side = models.CharField(max_length=1)  # r | b
    from_row = models.IntegerField()
    from_col = models.IntegerField()
    to_row = models.IntegerField()
    to_col = models.IntegerField()
    piece = models.CharField(max_length=5)
    captured = models.CharField(max_length=5, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
```

> Nếu muốn ra MVP nhanh hơn: có thể làm Game-only trước, Move làm sau.

---


## 7) API Endpoints (nhẹ, đủ chạy)
### 7.1 Create game
**POST** `/api/games/`
- Input: `{ "difficulty": "easy|normal|hard" }`
- Output: `{ "game_id": "...", ...state }`

### 7.2 Get game state
**GET** `/api/games/<id>/`
- Output: `...state`

### 7.3 Apply player move (core)
**POST** `/api/games/<id>/move`
- Input: `{ "from":[r,c], "to":[r,c] }`
- Server flow:
  1. Load Game + state
  2. Check status != finished
  3. Check đúng lượt người
  4. Apply move người bằng adapter
  5. Check endgame; nếu xong → save + return
  6. Pick AI move (sync) → apply
  7. Check endgame → save + return state

### 7.4 (Optional) Legal moves for highlight
**GET** `/api/games/<id>/legal-moves?from=[r,c]`
- Output: List các to hợp lệ

---


## 8) Trang web UI (Templates + JS/HTMX)
### 8.1 Route
**GET** `/game/<id>/` — Render `game.html`

### 8.2 UI responsibilities
- Render grid 10x9 từ `board_state`
- Map piece code → SVG/PNG icon (từ `static/games/pieces/`)
- Click flow:
  1. Click quân (chỉ cho chọn quân của player_side)
  2. Click ô đích
  3. Call API move
  4. Render board theo response

### 8.3 Static files
```bash
# Collect static files
python manage.py collectstatic
```
- Đặt SVG/PNG quân cờ trong `games/static/games/pieces/`
- Naming: `rK.svg`, `bR.png`, etc.

### 8.4 Nâng cấp UI (không bắt buộc)
- Highlight last move
- Highlight legal moves
- Move history sidebar
- Button restart/new game

---


## 9) AI (sync trước, nâng cấp sau)
### 9.1 Difficulty gợi ý
- **easy**: Random legal move
- **normal**: Greedy (ưu tiên ăn quân có giá trị cao)
- **hard**: Minimax depth thấp (nếu engine hỗ trợ)

### 9.2 Khi nào cần async
Nếu AI chạy > 1–2s:
- Dùng Celery/RQ
- API trả "AI thinking…"
- Khi xong update state (giai đoạn sau)

---

## 10) Testing tối thiểu (để không vỡ luật)
### 10.1 Engine/adapter tests
- State 10x9 validate
- Invalid move bị reject
- Apply move ra state đúng
- Endgame detection đúng

### 10.2 API tests
```python
# pytest/django test
- create game trả state đúng
- move valid: ok=true, state đổi
- move invalid: ok=false + error_code
- finished game: chặn move tiếp
```

---

## 11) Thứ tự làm (roadmap chuẩn, không mắc kẹt)
Đây là "hướng để làm trước" theo đúng ưu tiên.

### Phase 1 — Core trước (quan trọng nhất)
1. Chốt contract (move/state/response/error_code) trong chính file này (mục 3)
2. Làm `engine_adapter` chạy được bằng Python thuần:
   - `init/apply/check_endgame/pick_ai`
3. Tạo Django project + app `games`

### Phase 2 — API trước UI
1. Model `Game` + endpoint `POST /api/games/` + `GET /api/games/<id>/`
2. Endpoint core `POST /api/games/<id>/move` (người → AI)

### Phase 3 — UI (lúc này làm rất nhanh)
1. Template `/game/<id>/` render board
2. JS click-to-move gọi API + update board

### Phase 4 — Nâng cấp
1. Move history / legal-moves highlight
2. Tối ưu AI / async nếu cần
3. Auth, deploy, polish UI

---

## 12) Django Settings & Deployment
### 12.1 CORS (nếu frontend tách riêng)
```python
# settings.py
INSTALLED_APPS += ['corsheaders']
MIDDLEWARE = ['corsheaders.middleware.CorsMiddleware', ...]
CORS_ALLOWED_ORIGINS = ['http://localhost:3000']  # hoặc Next.js port
```

### 12.2 Static files production
```python
# settings.py
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']
```

### 12.3 Docker (optional)
```dockerfile
# Dockerfile
FROM python:3.11
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
RUN python manage.py collectstatic --noinput
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - ./db.sqlite3:/app/db.sqlite3
    environment:
      - DEBUG=0
```

---

## 13) Definition of Done (MVP)
✅ **Checklist MVP:**
- [ ] Tạo ván → hiển thị bàn cờ đúng
- [ ] Người đi hợp lệ → AI đi → board update đúng
- [ ] Invalid move bị chặn rõ ràng (error_code)
- [ ] Ván kết thúc có status/winner, không cho đi tiếp
- [ ] State lưu DB ổn định
- [ ] Static files (quân cờ) hiển thị đúng
- [ ] Tests pass (engine + API)

---

**Good luck! 🎯 Làm từng phase một, đừng nhảy cóc!**
