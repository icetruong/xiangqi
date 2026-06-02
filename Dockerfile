# Sử dụng phiên bản Python 3.10 chuẩn để khả năng tương thích thư viện cao nhất
FROM python:3.10-slim

# Thiết lập các biến môi trường
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Cài đặt gcc và libpq-dev phòng trường hợp cần thiết cho psycopg2 (dù docker python đã đủ tốt)
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy file requirements.txt
COPY requirements.txt /app/

# Nâng cấp PIP và cài đặt thư viện
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy phần code còn lại
COPY . /app/

# Build Cython extensions for faster AI (~10x speedup over pure Python)
RUN python setup_cython.py build_ext --inplace || echo "Cython build failed, falling back to pure Python"

# Mở port 8000
EXPOSE 8000

# Chạy collectstatic để tạo file tĩnh cho PWA và UI
RUN python manage.py collectstatic --noinput

# Khởi chạy server Daphne phục vụ cả HTTP lẫn Websocket (Django Channels)
CMD sh -c "python manage.py migrate && daphne -b 0.0.0.0 -p 8000 xiangqi_project.asgi:application"