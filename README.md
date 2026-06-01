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
- `mobile/flutter_xiangqi/overview.md`: thiết kế và hướng dẫn phát triển app Flutter

## Mobile (Flutter)

Dự án có app mobile Flutter đặt tại `mobile/flutter_xiangqi/`.

App Flutter hoạt động hoàn toàn như một **client thuần** — toàn bộ luật cờ, validation và AI đều chạy trên backend Django. Flutter chỉ render UI và gọi REST API.

### Chơi mobile khi backend host trên Railway

**Có, hoàn toàn được.** Khi backend đã deploy lên Railway, app Flutter trên điện thoại có thể kết nối trực tiếp — không cần server local hay tunnel.

Chỉ cần cập nhật một chỗ duy nhất trong Flutter:

```dart
// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'https://<tên-app-của-bạn>.up.railway.app';
  static const String apiPrefix = '/api';
}
```

Thay `<tên-app-của-bạn>` bằng domain Railway thực tế của bạn (ví dụ: `xiangqi-production.up.railway.app`).

### Checklist trước khi chạy mobile với Railway

Đảm bảo backend Railway đã cấu hình đúng các biến môi trường:

| Biến | Ghi chú |
|---|---|
| `ALLOWED_HOSTS` | Thêm domain Railway của bạn |
| `CSRF_TRUSTED_ORIGINS` | Thêm `https://<domain>.up.railway.app` |
| `SECRET_KEY` | Đặt giá trị ngẫu nhiên, bảo mật |
| `DEBUG` | Đặt `False` khi production |
| `DATABASE_URL` | Railway tự inject nếu dùng Railway Postgres |

### CORS với app mobile native

App Flutter native (Android/iOS) **không bị chặn bởi CORS** như trình duyệt web, vì request không xuất phát từ browser. Tuy nhiên backend vẫn cần `ALLOWED_HOSTS` đúng để Django không reject request.

### Chạy app trên laptop (development)

```bash
cd mobile/flutter_xiangqi
```

**Kiểm tra thiết bị / emulator khả dụng:**

```bash
flutter devices
```

**Chạy trên Android Emulator** (cần mở AVD trước từ Android Studio):

```bash
flutter run
```

**Chạy trên Chrome** (web, để test nhanh UI):

```bash
flutter run -d chrome
```

**Chạy trên Windows desktop:**

```bash
flutter run -d windows
```

> **Lưu ý khi chạy local:** Nếu backend đang chạy local (`localhost:8000` hoặc `localhost:8001`), cần cập nhật `baseUrl` trong `lib/core/constants/api_constants.dart`:
>
> ```dart
> // Khi test với backend local:
> static const String baseUrl = 'http://10.0.2.2:8000'; // Android Emulator
> // static const String baseUrl = 'http://localhost:8000'; // Chrome / Windows desktop
> ```
>
> Android Emulator dùng `10.0.2.2` thay cho `localhost` vì emulator chạy trong máy ảo riêng. Nếu backend đang tunnel qua Cloudflare hoặc đã host trên Railway, dùng URL đó luôn và không cần đổi.

### Phân phối app mobile — Deploy lên đâu?

> **App Flutter mobile (Android/iOS) KHÔNG deploy lên Railway.**
> Railway chỉ host backend Django. Flutter mobile là file APK/AAB cài thẳng lên điện thoại.

Có 3 hướng phân phối, tùy mục đích:

---

**Cách 1 — APK trực tiếp (nhanh nhất, dùng để test)**

Build file APK rồi gửi/cài thẳng:

```bash
cd mobile/flutter_xiangqi
flutter build apk --release
```

File APK xuất ra tại: `build/app/outputs/flutter-apk/app-release.apk`

Gửi file này qua Zalo / Drive / cáp USB rồi cài lên điện thoại Android (cần bật "Cài từ nguồn không xác định" trong Settings).

Cài nhanh qua USB:
```bash
flutter install
```

---

**Cách 2 — Google Play Store (phân phối chính thức)**

```bash
# Build Android App Bundle
cd mobile/flutter_xiangqi
flutter build appbundle --release
```

File AAB xuất ra tại: `build/app/outputs/bundle/release/app-release.aab`

Upload lên [Google Play Console](https://play.google.com/console) và publish. Cần tài khoản developer ($25 một lần).

---

**Cách 3 — Flutter Web + "Pin vào màn hình" điện thoại (PWA)**

Flutter Web build ra web app, deploy lên bất kỳ host nào có HTTPS, sau đó dùng tính năng "Thêm vào màn hình chính" của trình duyệt → trông và cảm giác gần như app native, có icon riêng, chạy toàn màn hình.

Flutter hỗ trợ PWA sẵn — không cần cấu hình thêm gì.

**Bước 1 — Build Flutter Web:**

```bash
cd mobile/flutter_xiangqi
flutter build web --release
```

File build xuất ra tại: `build/web/`

**Bước 2 — Deploy (chọn 1 trong 2):**

*Option A — Netlify Drop (nhanh nhất, miễn phí):*

Vào [netlify.com/drop](https://app.netlify.com/drop), kéo thả thư mục `build/web/` vào. Netlify tự cấp URL `https://....netlify.app` ngay lập tức.

*Option B — Deploy lên Railway (cùng project với backend):*

Cách này cho phép Flutter Web và Django backend cùng nằm trong một Railway project, tiện quản lý và chia sẻ cùng domain.

**Các file cần tạo** (đã có sẵn trong repo):

- [`mobile/flutter_xiangqi/Dockerfile.web`](mobile/flutter_xiangqi/Dockerfile.web) — Multi-stage build: build Flutter Web → serve bằng nginx
- [`mobile/flutter_xiangqi/nginx.conf`](mobile/flutter_xiangqi/nginx.conf) — Nginx config tối ưu cho SPA (gzip, cache, SPA routing)

**Quy trình deploy trên Railway:**

1. Vào [railway.app](https://railway.app) → mở project hiện tại của backend
2. Bấm **"+ New Service"** → chọn **"GitHub Repo"**
3. Chọn repo này (cùng repo với backend)
4. Railway sẽ hỏi Dockerfile path — nhập: `mobile/flutter_xiangqi/Dockerfile.web`
5. Đặt **Root Directory** là `mobile/flutter_xiangqi`
6. Railway tự build và cấp URL `https://....up.railway.app` riêng cho Flutter Web
7. Bấm **"Generate Domain"** để lấy URL HTTPS

> ⚠️ **Lưu ý Railway PORT**: Railway inject biến `PORT` động. Nginx trong Dockerfile.web lắng nghe cổng `80` cố định — Railway sẽ tự map đúng. Không cần thêm biến môi trường gì thêm cho service này.

> 💡 **Thời gian build**: Lần đầu build khá lâu (~5–10 phút) vì Railway phải pull Flutter image. Các lần sau build nhanh hơn nhờ layer cache.

**Bước 3 — Pin vào màn hình điện thoại:**

*Android (Chrome):*
1. Mở URL Flutter Web trên Chrome
2. Bấm menu **⋮** (3 chấm) góc trên phải
3. Chọn **"Thêm vào màn hình chính"** (hoặc "Add to Home screen")
4. Đặt tên → Thêm → icon xuất hiện trên màn hình như app thật

*iOS (Safari):*
1. Mở URL trên Safari (bắt buộc phải dùng Safari, không phải Chrome)
2. Bấm nút **Share** (hình vuông có mũi tên lên)
3. Chọn **"Add to Home Screen"**
4. Đặt tên → Add

> ✅ Sau khi pin, app chạy **toàn màn hình** (không có thanh địa chỉ browser), có icon riêng — trông như app native.
>
> ⚠️ Cần HTTPS để tính năng "Add to Home Screen" hoạt động đầy đủ. Netlify và Railway đều cấp HTTPS miễn phí.

---

**Tóm tắt**

| Mục đích | Hướng làm |
|---|---|
| Test nhanh cho bản thân | Build APK → cài qua USB |
| Chia sẻ cho bạn bè test | Build APK → gửi file |
| Pin vào màn hình như app | Flutter Web → Netlify / Railway → Add to Home Screen |
| Phân phối chính thức | Google Play (AAB) |
| Backend / API | Railway (Django) ← đang chạy rồi ✅ |

Xem thêm chi tiết kiến trúc, các phases phát triển và API contract trong [`mobile/flutter_xiangqi/overview.md`](mobile/flutter_xiangqi/overview.md).
