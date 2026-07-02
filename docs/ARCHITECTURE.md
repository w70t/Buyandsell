# المعمارية — Souqna Architecture

> **التأكيد الأساسي:** المشروع يعمل على Raspberry Pi 5 (8GB) بنفس حاويات Docker التي
> تعمل لاحقاً على VPS أو سحابة. **لا شيء في الكود مربوط بالراسبيري** — كل ما يتغيّر عند
> الانتقال هو ملف `.env` (وربما عدد الـ workers). راجع `MIGRATION_TO_VPS.md`.

## نظرة عامة

```
                        ┌──────────────────────────────────────────┐
 المتصفح / تطبيق Flutter │              docker compose              │
        │               │  ┌───────┐   ┌────────────┐   ┌────────┐ │
        └── :8080 ───────▶ │ nginx │──▶│  api        │──▶│ db     │ │
                        │  │ (80)  │   │ FastAPI     │   │ Postgres│ │
                        │  └───┬───┘   │ + web (SSR) │   └────────┘ │
                        │      │       └─────┬──────┘               │
                        │   /media ◀── uploads volume               │
                        │  [redis]* ◀── rate limits   [minio]* ◀── صور │
                        └──────────────────────────────────────────┘
                                  * اختياري عبر --profile
```

خدمة واحدة (FastAPI) تقدّم ثلاث واجهات من نفس الكود ونفس قاعدة البيانات:

| الواجهة | المسار | الاستخدام |
|---|---|---|
| REST API (JSON) | `/api/*` | تطبيق Flutter + أي عميل خارجي (توثيق OpenAPI على `/api/docs`) |
| الموقع العام (SSR) | `/` | تصفّح، بحث، نشر، محادثة، مفضلة، إشعارات، إبلاغ — HTML من الخادم (صديق لمحركات البحث) |
| لوحة الإدارة | `/admin` | إحصاءات، مستخدمون، إعلانات، بلاغات، أقسام، سجل تدقيق |

## لماذا هذا التصميم مناسب للراسبيري وقابل للتوسّع؟

1. **عملية واحدة تخدم كل شيء** — SSR بـ Jinja2 لا يحتاج Node أو عملية Frontend منفصلة؛
   استهلاك الذاكرة الكلي للمنصّة < 1GB من أصل 8GB.
2. **كل الإعدادات متغيّرات بيئة** (12-factor). `app/core/config.py` هو المصدر الوحيد.
3. **طبقات قابلة للتبديل بمتغيّر واحد:**
   - التخزين: `STORAGE_BACKEND=local` (قرص) ⇠⇢ `minio` (S3) — الواجهة `app/services/storage.py`.
   - حدود الطلبات: ذاكرة العملية ⇠⇢ Redis عبر `REDIS_URL` — للتوسّع لعدة workers.
   - إشعارات تيليغرام: تعمل فقط إذا وُجد `TELEGRAM_BOT_TOKEN` — المنصّة لا تعتمد عليها.
4. **Postgres منذ اليوم الأول** (لا SQLite في الإنتاج) — الترحيل = `pg_dump` ثم استعادة.
5. **صور متعددة المعماريات**: `python:3.11-slim` و`postgres:16-alpine` و`nginx:alpine` تُبنى
   على arm64 (الراسبيري) و amd64 (VPS) بنفس Dockerfile.

## بنية الكود (backend)

```
app/
├── core/        # config (env), security (Argon2id+JWT), rate_limit, deps, logging
├── db/          # engine/session (async SQLAlchemy) + Base
├── models/      # user, category, listing, listing_image, favorite, message,
│                #   report, notification, audit_log
├── schemas/     # Pydantic (تحقق المدخلات + أشكال الاستجابة)
├── services/    # storage (local/S3), notify (in-app + Telegram), moderation
├── api/routes/  # auth, categories, listings, favorites, messages,
│                #   notifications, reports, admin, health
└── web/         # SSR: deps (كوكيز JWT + CSRF), routes_public, routes_admin,
                 #   templates/ (Jinja2), static/ (CSS + خط Cairo مضمّن)
```

قاعدة مهمة: منطق الأعمال المشترك (البلاغات، الإشعارات) يعيش في `services/` ويُستدعى من
الـ API والويب معاً — لا تكرار.

## المصادقة

- **API:** JWT (Access 30 دقيقة / Refresh 30 يوماً مع تدوير) في ترويسة Authorization.
- **الويب:** نفس الـ JWT داخل كوكيز HttpOnly (`sq_access`/`sq_refresh`) مع تدوير صامت
  عند الانتهاء، وحماية CSRF بنمط double-submit (`sq_csrf` + حقل مخفي في كل نموذج).

## تدفّق البيانات الحرجة

- **صورة مرفوعة:** تحقق الحجم ⇠ إعادة ترميز عبر Pillow (يمنع الملفات المموّهة ويمسح
  EXIF) ⇠ تخزين local/S3 ⇠ الرابط يُبنى من `PUBLIC_BASE_URL` وقت القراءة (يبقى صحيحاً
  بعد تغيير الدومين).
- **بلاغ:** إنشاء ⇠ عند بلوغ `REPORTS_AUTO_HIDE_THRESHOLD` بلاغات مفتوحة يُخفى الإعلان
  تلقائياً + إشعار للمالك + سجل تدقيق + تيليغرام للمشرف ⇠ المشرف يعالج من `/admin/reports`
  (إخفاء/حذف/حظر/رفض) وكل إجراء مسجَّل في `audit_logs`.

## مسار النمو (بدون إعادة كتابة)

| المرحلة | التغيير المطلوب |
|---|---|
| Pi → VPS | نقل `.env` + نسخة `pg_dump` + مجلد uploads؛ رفع `UVICORN_WORKERS` |
| عدة workers | ضبط `REDIS_URL` وتشغيل `--profile redis` |
| نمو الصور | `STORAGE_BACKEND=minio` (أو S3 حقيقي بتغيير endpoint/credentials) |
| فصل قاعدة البيانات | تغيير `DATABASE_URL` إلى Postgres مُدار (RDS/DO) |
| عدة خوادم API | نفس الصورة خلف Load Balancer؛ الحالة كلها في Postgres/Redis/S3 |
