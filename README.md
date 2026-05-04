# Cờ Tướng (Xiangqi)

Dự án cờ tướng xây dựng bằng Django, trong đó:
- `games/` chứa giao diện web, API và lưu trữ trận đấu.
- `engine/` chứa luật di chuyển, kiểm tra hợp lệ và AI.
- `tests/` chứa test cho engine và adapter.

## Yêu cầu

- Python 3.10 trở lên
- `pip`
- Khuyến nghị dùng virtual environment (môi trường ảo)
- Docker (nếu chạy qua Docker)

## Cài đặt nhanh

1. Tạo môi trường ảo:

```bash
python -m venv .venv
```

2. Kích hoạt:

- Windows PowerShell:

```bash
.venv\Scripts\Activate.ps1
```

- macOS/Linux:

```bash
source .venv/bin/activate
```

3. Cài dependency:

```bash
pip install -r requirements.txt
```

4. Tạo file môi trường:

```bash
copy .env.example .env
```

Nếu bạn đang ở macOS/Linux, dùng:

```bash
cp .env.example .env
```

## Chạy dự án

1. Chạy migration:

```bash
python manage.py migrate
```

2. Tạo tài khoản admin nếu cần:

```bash
python manage.py createsuperuser
```

3. Chạy server:

```bash
python manage.py runserver
```

`manage.py` đã gắn mặc định `127.0.0.1:8001` cho lệnh `runserver`, nên bạn có thể mở:
- Trang chủ: `http://127.0.0.1:8001/`
- Admin: `http://127.0.0.1:8001/admin/`

## Hướng dẫn Deploy / Chạy Online qua Cloudflare Tunnel

Để public game cho người khác cùng chơi (ví dụ: chạy trên port `8000` thông qua Docker hoặc Daphne), bạn có thể dùng Cloudflare Tunnel.

Mở một terminal mới (không tắt terminal đang chạy server) và sử dụng lệnh sau:

```bash
npx cloudflared tunnel run --url http://localhost:8000 xiangqi-app
```

*Lưu ý: 
- Bạn cần cài đặt Node.js để có thể sử dụng lệnh `npx`.
- Đảm bảo rằng port trong URL (`8000`) trùng khớp với port ứng dụng của bạn đang chạy (chỉnh thành `8001` nếu dùng `runserver` mặc định của dự án).
- Nhớ cập nhật `ALLOWED_HOSTS` và `CSRF_TRUSTED_ORIGINS` trong file `.env` với domain được cấp hoặc cấu hình sẵn để không bị lỗi bảo mật (CORS/CSRF) của Django.*

## Biến môi trường

File mẫu nằm ở `.env.example`.

Biến quan trọng:
- `SECRET_KEY`: khóa bí mật của Django
- `DEBUG`: bật/tắt debug mode
- `ALLOWED_HOSTS`: danh sách host được phép truy cập
- `CSRF_TRUSTED_ORIGINS`: domain tin cậy cho form/API
- `DATABASE_URL`: nếu không set thì dự án sẽ dùng SQLite local
- `AI_EASY_DEPTH`, `AI_NORMAL_DEPTH`, `AI_HARD_DEPTH`: mức độ tìm kiếm của AI

## Testing

Chạy toàn bộ test:

```bash
pytest
```

Hiện tại test suite backend được dùng để bảo vệ:
- luật di chuyển của từng quân
- logic check / self-check
- game status
- contract adapter giữa API và engine

## Kiến trúc nhanh

- `games/services/engine_adapter.py`: cầu nối giữa Django và engine
- `games/services/game_service.py`: tạo game, xử lý nước đi và AI worker
- `games/api_views.py`: REST API cho frontend
- `engine/rules/`: các rule kiểm tra hợp lệ, check và sinh nước đi
- `engine/ai/`: minimax, move ordering, quiescence và time search

## Ghi chú về AI chạy nền

Sau khi người chơi đi nước, API trả kết quả ngay và AI sẽ được kích hoạt bằng worker thread nên ở local/game demo cảm giác sẽ mượt hơn.

Vì AI đi bất đồng bộ:
- frontend nên gọi lại endpoint chi tiết game để lấy nước đi mới nhất của AI
- khi deploy thật, nếu cần độ ổn định cao hơn, nên thay worker thread bằng queue/job worker riêng

## Static files và deploy

- Static được phục vụ bằng WhiteNoise.
- `STATIC_ROOT` là `staticfiles/`.
- `Procfile` hiện tại chạy `migrate` rồi khởi động `gunicorn`.

Nếu bạn deploy lên Railway hoặc nền tảng tương tự, hãy kiểm tra lại:
- `ALLOWED_HOSTS`
- `CSRF_TRUSTED_ORIGINS`
- `DATABASE_URL`
- `SECRET_KEY`
- `DEBUG=False`

## Tài liệu bổ sung

- `CONTRACT.md`: mô tả contract dữ liệu và API
- `roadmap.md`: hướng phát triển tiếp theo
- `docs/state_format.md`: format state của bàn cờ
