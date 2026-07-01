# Multi-arch image: builds the same on Raspberry Pi (arm64) and on a VPS (amd64).
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# System deps needed by asyncpg / Pillow / argon2 wheels.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential libpq-dev libjpeg62-turbo-dev zlib1g-dev curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . .
RUN chmod +x scripts/*.sh

# Non-root user for safety.
RUN useradd -m appuser && mkdir -p /data/uploads && chown -R appuser:appuser /data /app
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
    CMD curl -fsS http://localhost:8000/api/health || exit 1

ENTRYPOINT ["./scripts/entrypoint.sh"]
