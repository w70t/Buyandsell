# قاعدة البيانات — Souqna Database

PostgreSQL 16 · SQLAlchemy 2 (async) · مهاجرات Alembic (`backend/alembic/`).
المهاجرات تُطبَّق تلقائياً عند إقلاع الحاوية (`entrypoint.sh` ⇠ `alembic upgrade head`).

## الجداول

### users
| العمود | النوع | ملاحظات |
|---|---|---|
| id | int PK | |
| name | varchar(120) | |
| phone | varchar(32) unique | رقم عراقي بصيغة 07XXXXXXXXX — هوية الدخول |
| password_hash | varchar(255) | Argon2id |
| role | varchar(16) | `user` / `admin` |
| is_active, is_banned | bool | الحظر يمنع الدخول والتحديث |
| created_at, updated_at | timestamp | |

### categories
`id, slug (unique), name_ar, subtitle_ar, icon, sort_order, is_active` — تُبذر 15 قسماً
افتراضياً عند أول إقلاع (`app/seed.py`) وتُدار من `/admin/categories`.

### listings
| العمود | النوع | ملاحظات |
|---|---|---|
| id | int PK | |
| title | varchar(140) index | |
| description | text | |
| price | bigint | بالدينار العراقي |
| currency | varchar(8) | افتراضي IQD |
| negotiable | bool | |
| condition | varchar(16) | `new` / `used` |
| category_id | FK → categories (RESTRICT) | |
| governorate, city | varchar | المحافظة مفهرسة |
| seller_id | FK → users (CASCADE) | |
| status | varchar(16) index | `active` / `sold` / `hidden` |
| views | int | يزيد عند مشاهدة غير المالك |

### listing_images
`id, listing_id FK(CASCADE), url, key, position` — `key` هو مسار التخزين؛ الـ URL يُعاد
بناؤه من `PUBLIC_BASE_URL` وقت القراءة فيبقى صحيحاً بعد تغيير الدومين.

### favorites
مفتاح مركّب `(user_id, listing_id)` + `created_at`. الحذف يتبع المستخدم أو الإعلان.

### messages
`id, conversation_id (index), listing_id, sender_id, receiver_id, body, is_read, created_at`
— `conversation_id` مفتاح حتمي `c.{listing}.{min_uid}.{max_uid}` يضمن خيطاً واحداً لكل
(إعلان، طرفين).

### reports (البلاغات)
| العمود | ملاحظات |
|---|---|
| reporter_id | FK → users (CASCADE) |
| listing_id / reported_user_id | FK بـ SET NULL — البلاغ يبقى بعد حذف الهدف |
| reason | scam / prohibited / offensive / spam / other |
| details, status | status: open / resolved / dismissed |
| action | none / hide_listing / delete_listing / ban_user |
| resolved_by, resolved_at | من عالج ومتى |

قيد منطقي (في الخدمة): بلاغ مفتوح واحد لكل (مبلّغ، هدف)؛ عند بلوغ
`REPORTS_AUTO_HIDE_THRESHOLD` بلاغات مفتوحة يُخفى الإعلان تلقائياً.

### notifications
`id, user_id FK(CASCADE), type (message|favorite|moderation|system), title, body,
link, is_read, created_at` — `link` مسار نسبي (يصمد أمام تغيير الدومين).

### audit_logs
`id, admin_id FK(SET NULL — NULL = النظام), action, target_type, target_id, note,
created_at` — سجل غير قابل للتعديل لكل إجراء إداري.

## المهاجرات

| النسخة | المحتوى |
|---|---|
| 0001_init | users, categories, listings, listing_images, favorites, messages |
| 0002_moderation | reports, notifications, audit_logs |

إنشاء مهاجرة جديدة: عدّل الـ models ثم
`docker compose exec api alembic revision --autogenerate -m "وصف"` وراجع الملف الناتج.

## نسخ احتياطي واستعادة

`backend/scripts/backup.sh` (يُشغَّل من cron) يدفع `pg_dump` مضغوطاً + أرشيف الصور إلى
`backups/` مع تنظيف ما هو أقدم من `RETENTION_DAYS`. الاستعادة موثّقة في رأس الملف
وفي `MIGRATION_TO_VPS.md`.
