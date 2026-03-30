# Xiangqi PvE

Du an co tuong PvE xay dung bang Django, trong do:
- `games/` chua giao dien web, API va luu tru tran dau.
- `engine/` chua luat di chuyen, kiem tra hop le va AI.
- `tests/` chua test cho engine va adapter.

## Yeu cau

- Python 3.10 tro len
- `pip`
- Khuyen nghi dung virtual environment

## Cai dat nhanh

1. Tao moi truong ao:

```bash
python -m venv .venv
```

2. Kich hoat:

- Windows PowerShell:

```bash
.venv\Scripts\Activate.ps1
```

- macOS/Linux:

```bash
source .venv/bin/activate
```

3. Cai dependency:

```bash
pip install -r requirements.txt
```

4. Tao file moi truong:

```bash
copy .env.example .env
```

Neu ban dang o macOS/Linux, dung:

```bash
cp .env.example .env
```

## Chay du an

1. Chay migration:

```bash
python manage.py migrate
```

2. Tao tai khoan admin neu can:

```bash
python manage.py createsuperuser
```

3. Chay server:

```bash
python manage.py runserver
```

`manage.py` da gan mac dinh `127.0.0.1:8001` cho lenh `runserver`, nen ban co the mo:
- Trang chu: `http://127.0.0.1:8001/`
- Admin: `http://127.0.0.1:8001/admin/`

## Bien moi truong

File mau nam o `.env.example`.

Bien quan trong:
- `SECRET_KEY`: khoa bi mat cua Django
- `DEBUG`: bat/tat debug mode
- `ALLOWED_HOSTS`: danh sach host duoc phep
- `CSRF_TRUSTED_ORIGINS`: domain tin cay cho form/API
- `DATABASE_URL`: neu khong set thi du an se dung SQLite local
- `AI_EASY_DEPTH`, `AI_NORMAL_DEPTH`, `AI_HARD_DEPTH`: muc do tim kiem cua AI

## Testing

Chay toan bo test:

```bash
pytest
```

Hien tai test suite backend duoc dung de bao ve:
- luat di chuyen cua tung quan
- logic check / self-check
- game status
- contract adapter giua API va engine

## Kien truc nhanh

- `games/services/engine_adapter.py`: cau noi giua Django va engine
- `games/services/game_service.py`: tao game, xu ly nuoc di va AI worker
- `games/api_views.py`: REST API cho frontend
- `engine/rules/`: cac rule kiem tra hop le, check va sinh nuoc di
- `engine/ai/`: minimax, move ordering, quiescence va time search

## Ghi chu ve AI chay nen

Sau khi nguoi choi di nuoc, API tra ket qua ngay va AI se duoc kich hoat bang worker thread nen o local/game demo cam giac se muot hon.

Vi AI di bat dong bo:
- frontend nen goi lai endpoint chi tiet game de lay nuoc di moi nhat cua AI
- khi deploy that, neu can do on dinh cao hon, nen thay worker thread bang queue/job worker rieng

## Static files va deploy

- Static duoc phuc vu bang WhiteNoise.
- `STATIC_ROOT` la `staticfiles/`.
- `Procfile` hien tai chay `migrate` roi khoi dong `gunicorn`.

Neu ban deploy len Railway hoac nen tang tuong tu, hay kiem tra lai:
- `ALLOWED_HOSTS`
- `CSRF_TRUSTED_ORIGINS`
- `DATABASE_URL`
- `SECRET_KEY`
- `DEBUG=False`

## Tai lieu bo sung

- `CONTRACT.md`: mo ta contract du lieu va API
- `roadmap.md`: huong phat trien tiep theo
- `docs/state_format.md`: format state cua ban co
