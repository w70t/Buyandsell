# سوقنا — Souqna 🛒
Marketplace (buy & sell) for Iraq — Flutter app + public SSR website, backed by a real FastAPI/PostgreSQL API. No fake data: images are really uploaded and stored. Built to run on a Raspberry Pi first, then move to a VPS with the same Docker containers.

## Status  (AI must update this at end of every task)
Working: backend API (auth, listings, categories, favorites, messages, notifications, reports, admin), public SSR website (`/`), admin web panel (`/admin`), Flutter mobile app, Docker stack (api + db + nginx, optional redis/minio), Alembic migrations, backend + e2e tests.
In progress: none — see docs/ROADMAP.md for planned features.
Known bugs: none recorded.
Last updated: 2026-07-04

## Stack
- Backend: Python 3.11, FastAPI 0.115, Uvicorn, SQLAlchemy 2 (async), Alembic, Pydantic 2
- DB: PostgreSQL 16 (asyncpg)
- Storage: local disk (default) or MinIO/S3 (one env var swap)
- Auth/security: Argon2id, JWT (access/refresh with rotation), slowapi rate limiting, Pillow image re-encode
- Web (SSR): Jinja2 templates (Arabic RTL) served by FastAPI
- Mobile: Flutter (Dart >=3.3), Material 3, Dio, Provider, flutter_secure_storage, Cairo font
- Infra: Docker + docker-compose, Nginx reverse proxy (serves `/media`, proxies `/api`)

## Run — dev
Backend tests (no Docker):
  cd backend && pip install -r requirements-dev.txt && pytest
Full stack (Docker):
  cp .env.example .env      # set SECRET_KEY, DB password, PUBLIC_BASE_URL
  mkdir -p data/uploads && sudo chown -R 1000:1000 data/uploads
  docker compose up -d --build
  # site: http://localhost:8080  | admin: /admin | api: /api | docs: /api/docs
Mobile:
  cd mobile && flutter create . --platforms=android --org iq.souqna   # once
  flutter pub get
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   # android emulator
Boot auto-runs: wait for DB → apply migrations → seed categories + admin → start API.

## Run — Raspberry Pi / VPS
git clone → cp .env.example .env → fill secrets (SECRET_KEY, POSTGRES_PASSWORD,
PUBLIC_BASE_URL, ADMIN_PASSWORD) → docker compose up -d --build
Same containers on Pi and VPS — only env values / API URL change.
Logs: docker compose logs -f api
Deploy details (Cloudflare Tunnel, HTTPS, backups): docs/DEPLOYMENT.md

## Key files
backend/app/main.py               — FastAPI app entry (API + SSR mount)
backend/app/api/routes/           — REST endpoints (auth, listings, categories, favorites, messages, notifications, reports, admin)
backend/app/web/routes_public.py  — public SSR site (browse/post/chat)
backend/app/web/routes_admin.py   — admin web panel (/admin)
backend/app/models/               — SQLAlchemy models (user, listing, category, message, report, notification, favorite, audit_log)
backend/app/core/                 — config, security (JWT/Argon2), deps, rate_limit, logging
backend/app/services/             — moderation, notify (telegram), storage (local/minio)
backend/app/seed.py               — seeds categories + admin on first boot
backend/alembic/versions/         — DB migrations
mobile/lib/                       — Flutter app (core/, screens, providers)
docker-compose.yml                — api + db + nginx (+ redis/minio profiles)

## Secrets (.env — never committed)
See .env.example. Keys: SECRET_KEY, POSTGRES_USER/PASSWORD/DB, DATABASE_URL,
STORAGE_BACKEND, UPLOAD_DIR, MINIO_* , REDIS_URL, TELEGRAM_BOT_TOKEN,
TELEGRAM_ADMIN_CHAT_ID, ADMIN_PHONE/NAME/PASSWORD, PUBLIC_BASE_URL, CORS_ORIGINS.

## Runtime settings
No admin-editable `settings` table exists. Deploy/tuning config lives in `.env`
(e.g. REPORTS_AUTO_HIDE_THRESHOLD, RATE_LIMIT_*, ACCESS/REFRESH token expiry).
The admin panel (`/admin` + `/api/admin`) manages data at runtime: categories,
users (ban/roles), listings, reports, and the audit log — not app config.

## Language / RTL
UI language: ar (Arabic)   RTL: yes   (Cairo font; app also supports dark/light theme)

## Do not touch
- .env / real secrets — only .env.example is committed.
- alembic/versions/* already-applied migrations — add a new migration, never edit old ones.
- dist/ release artifacts (APK).

## Rules for any AI agent (non-negotiable)
Real code only — no placeholders, no fake data, no dead buttons.
Never restart or delete without "DELETE APPROVED"/"REWRITE APPROVED".
Smallest safe change; read files before editing.
Secrets → .env only. Admin-managed data → admin panel + API.
One step at a time: code + run command + expected result, then wait.
Pin dependency versions. Say "VERIFY:" when unsure — never guess.
Update the Status block above at the end of every task.
