#!/usr/bin/env bash
# Database + uploads backup. Run from cron, e.g. daily at 03:00:
#   0 3 * * * /path/to/backend/scripts/backup.sh >> /var/log/souqna-backup.log 2>&1
#
# Restore DB:   gunzip -c db_YYYYmmdd.sql.gz | docker compose exec -T db psql -U "$POSTGRES_USER" "$POSTGRES_DB"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"
STAMP="$(date +%Y%m%d_%H%M%S)"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

mkdir -p "$BACKUP_DIR"

# Load env from repo root if present.
[ -f "$ROOT_DIR/.env" ] && set -a && . "$ROOT_DIR/.env" && set +a

echo "[backup] dumping database -> $BACKUP_DIR/db_$STAMP.sql.gz"
docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T db \
    pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip > "$BACKUP_DIR/db_$STAMP.sql.gz"

echo "[backup] archiving uploads -> $BACKUP_DIR/uploads_$STAMP.tar.gz"
if [ -d "$ROOT_DIR/data/uploads" ]; then
    tar -czf "$BACKUP_DIR/uploads_$STAMP.tar.gz" -C "$ROOT_DIR/data" uploads
fi

echo "[backup] pruning backups older than $RETENTION_DAYS days"
find "$BACKUP_DIR" -name '*.gz' -mtime "+$RETENTION_DAYS" -delete

echo "[backup] done."
