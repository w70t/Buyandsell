# Multi-arch image: builds the same on Raspberry Pi (arm64) and on a VPS (amd64).
# No apt layer needed: every dependency ships pre-built manylinux wheels for
# both amd64 and arm64, which keeps builds fast on the Pi and the image small.
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

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
    CMD ["python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8000/api/health', timeout=4).status == 200 else 1)"]

ENTRYPOINT ["./scripts/entrypoint.sh"]
