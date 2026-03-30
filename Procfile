web: python manage.py migrate --noinput && gunicorn xiangqi_project.wsgi:application --bind 0.0.0.0:${PORT:-8001}
