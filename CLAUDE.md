# <Project Name>
<One line: what it does, for whom.>

## Status  (AI must update this at end of every task)
Working: Web UI + admin panel use a modern inline-SVG icon set (app/web/icons.py); all 34 backend tests pass. Flutter app gained modern micro-interactions: haptics (fav/tabs/categories/contact), press-scale (cards/categories/search), staggered grid entrance, and Hero image transition card→detail (new PressableScale/EntranceFade in widgets/common.dart).
In progress: none
Known bugs: none — note: Flutter toolchain not available in this env, so changes were verified by static bracket/API review, not `flutter analyze`.
Last updated: 2026-07-23

## Stack
<e.g., Python 3.11, aiogram 3, FastAPI, SQLite (WAL), vanilla JS admin>

## Run — dev
<commands, in order>

## Run — Raspberry Pi / VPS
git clone → cp .env.example .env → fill secrets → <install cmd> →
sudo systemctl enable --now <service>.service
Logs: journalctl -u <service> -f

## Key files
<path> — <purpose>          (max ~12 lines; only files that matter)

## Secrets (.env — never committed)
See .env.example. Keys: <BOT_TOKEN, ADMIN_ID, DB_PATH, PORT, ...>

## Runtime settings (admin-editable, NOT in .env)
Stored in: settings table (key, value, updated_at)
Edited via: <admin panel /admin | Telegram admin menu>
Keys: <welcome_text, daily_limit, feature_x_enabled, ...>

## Language / RTL
UI language: <ar | en | both>   RTL: <yes/no>

## Do not touch
<files/features the AI must never modify without approval>

## Rules for any AI agent (non-negotiable)
Real code only — no placeholders, no fake data, no dead buttons.
Never restart or delete without "DELETE APPROVED"/"REWRITE APPROVED".
Smallest safe change; read files before editing.
Secrets → .env only. Runtime settings → settings table + admin UI.
One step at a time: code + run command + expected result, then wait.
Pin dependency versions. Say "VERIFY:" when unsure — never guess.
Update the Status block above at the end of every task.
