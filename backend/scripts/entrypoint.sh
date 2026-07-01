#!/usr/bin/env bash
set -e

echo "[entrypoint] waiting for database..."
python -m app.wait_for_db

echo "[entrypoint] running migrations..."
alembic upgrade head

echo "[entrypoint] seeding base data (categories + admin)..."
python -m app.seed

echo "[entrypoint] starting API..."
# Workers can be raised on a VPS; keep it low on a Raspberry Pi.
# --proxy-headers makes the real client IP (X-Forwarded-For) available to rate limiting.
exec uvicorn app.main:app \
    --host 0.0.0.0 --port 8000 \
    --workers "${UVICORN_WORKERS:-1}" \
    --proxy-headers --forwarded-allow-ips="*"
