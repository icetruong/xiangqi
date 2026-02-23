# Hướng Dẫn Chạy Project Cờ Tướng (Xiangqi PvE)

Tài liệu này hướng dẫn cách cài đặt, khởi chạy dự án Cờ Tướng (Django) trên môi trường phát triển cục bộ (Local Development) và một vài lưu ý quan trọng trong quá trình phát triển/sửa lỗi.

---

## 1. Yêu Cầu Hệ Thống (Prerequisites)
- **Python**: Phiên bản 3.10 trở lên (Khuyến nghị sử dụng Python 3.10 - 3.12).
- **pip**: Trình quản lý gói mặc định của Python.
- **Git**: (Tuỳ chọn) Dành cho việc clone project hoặc quản lý version.

---

## 2. Các Bước Cài Đặt Và Chạy (Installation & Running)

### Bước 1: Tạo môi trường ảo (Virtual Environment)
Nên sử dụng môi trường ảo để các thư viện không bị xung đột với các project Python khác trên máy của bạn. Mở terminal tại thư mục gốc của project (`d:\TaiLieuNam3_DUT\HKII\Python\xiangqi`) và chạy lệnh sau:
```bash
python -m venv .venv
```

### Bước 2: Kích hoạt môi trường ảo
Sau khi tạo, bạn cần kích hoạt nó:
- **Trên Windows** (Command Prompt hoặc PowerShell):
  ```bash
  .venv\Scripts\activate
  ```
- **Trên macOS/Linux**:
  ```bash
  source .venv/bin/activate
  ```
*(Dấu hiệu nhận biết kích hoạt thành công là ở đầu dòng lệnh terminal sẽ xuất hiện chữ `(.venv)`).*

### Bước 3: Cài đặt thư viện (Dependencies)
Với môi trường ảo đã được kích hoạt, tiến hành cài đặt các gói cần thiết từ file `requirements.txt`:
```bash
pip install -r requirements.txt
```

### Bước 4: Cấu hình biến môi trường (Environment Variables)
Dự án yêu cầu một số biến môi trường để cấu hình (ví dụ: database, khoá bí mật, tuỳ biến AI). 
Hãy sao chép nội dung từ file mẫu `.env.example` và tạo ra môt file có tên là `.env` đặt ngay tại thư mục gốc của project:
- **Trên Windows** có thể dùng:
  ```bash
  copy .env.example .env
  ```
*(Phần cấu hình mặc định trong file `.env.example` đã đủ để khởi chạy cục bộ dự án với Database là SQLite3 và Debug=True nên bạn không cần phải sửa nội dung bên trong trừ khi muốn đẩy lên production hoặc muốn chỉnh các thông số chuyên sâu).*

### Bước 5: Khởi tạo cơ sở dữ liệu (Migrations)
Dự án Django cần tạo cấu trúc bảng trong cơ sở dữ liệu để hoạt động. Chạy các lệnh sau:
```bash
python manage.py makemigrations
python manage.py migrate
```

### Bước 6: Tạo tài khoản quản trị (Superuser) - *Tuỳ chọn*
Để có thể quản trị database qua trang admin của Django, bạn cần tạo 1 tài khoản với quyền cao nhất:
```bash
python manage.py createsuperuser
```
*(Terminal sẽ yêu cầu bạn nhập `Username`, `Email address`, và `Password`).*

### Bước 7: Khởi chạy Server
Bắt đầu chạy project với lệnh:
```bash
python manage.py runserver
```

Server sẽ khởi chạy tại cổng nội bộ. Lúc này bạn có thể mở Website lên thông qua trình duyệt tại:
- **Giao diện game (Người dùng)**: `http://127.0.0.1:8000/` (hoặc các đường dẫn views được quy định tuỳ theo config trong thư mục `xiangqi_project/urls.py`).
- **Giao diện trang Quản trị**: `http://127.0.0.1:8000/admin/`

---

## 3. Các Lưu Ý Quan Trọng Của Dự Án (Important Notes)

1. **Giao Diện & Frontend (Chủ đề Cổ trang - Wuxia)**:
   - Các files như HTML, CSS, JavaScript (Bao gồm hình ảnh bàn cờ, font chữ cờ tướng, logic bắt/thả quân cờ bằng JS...) nằm chính tại app `games/` (`games/templates/games/` và `games/static/games/`).
   - Project sử dụng hệ thống custom Modals (bảng xác nhận ván game, thoát game, xin hoà) thay vì browser alerts mặc định.
   - **Lưu ý bộ đệm (Cache)**: Khi bạn thay đổi code CSS / JS hoặc Font, hãy luôn sử dụng tổ hợp phím **`Ctrl + F5`** (hoặc Cmd + Shift + R trên Mac) trên trình duyệt để load lại code mới cứng thay vì code cũ được lưu cục bộ trên trình duyệt.

2. **Cấu Trúc Engine AI**:
   - Logic bộ não chơi Cờ tướng (AI) được đóng gói bên trong thư mục `engine/`. Đây là core AI giúp đánh với người chơi máy tính.
   - Mức độ thông minh (hay thời gian nghĩ) của máy có thể được can thiệp vào thông qua các biến cấu hình trong file `.env`: `AI_EASY_DEPTH`, `AI_NORMAL_DEPTH`, `AI_HARD_DEPTH`. Depth (độ sâu) càng lớn thì AI càng mạnh nhưng nghĩ càng lâu.

3. **Database (Bộ CSDL)**:
   - Hiện tại ở bản dev project dùng **SQLite3** thông qua file `db.sqlite3` được tự động tạo ở bước 5. Nếu sau này đưa lên môi trường sản xuất thực tế thì có thể đổi thành PostgreSQL bằng cách truy cập `xiangqi_project/settings.py` và bỏ comment kết nối psycopg2.

4. **Testing (Kiểm thử code)**:
   - Dự án được tích hợp bộ pytest cho Backend (thư mục `tests/`).
   - Khi sửa đổi logic Backend hay Engine mà bạn muốn biết mình có làm break code hệ thống không, hãy gõ lệnh:
     ```bash
     pytest
     ```
   - (Bạn có thể chạy thử các kịch bản check Database qua file `verify_db.py` và test adapter qua file `test_adapter.py` tuỳ lúc cần thiết).

5. **Đọc thêm về lộ trình dự án**:
   - Các định hướng về project (roadmap) hay nguyên tắc phát triển đã được tổng hợp ở file `roadmap.md` và `CONTRACT.md` tại thư mục gốc. Nên tham khảo 2 file này nếu chuẩn bị viết code chức năng mới.
