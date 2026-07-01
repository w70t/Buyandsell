# سوقنا — Souqna 🛒

منصّة **بيع وشراء في العراق** (بأسلوب مشابه لتطبيقات الإعلانات المبوّبة مثل Kleinanzeigen،
لكن بعلامة وتصميم مختلفين). كل شيء **حقيقي** — لا بيانات وهمية: تطبيق Flutter يتصل بـ
Backend حقيقي (FastAPI + PostgreSQL) عبر REST، مع صور تُرفع وتُخزَّن فعلياً.

مبني ليعمل **تجريبياً على Raspberry Pi ثم يُنقل إلى VPS/Domain بنفس حاويات Docker**
دون إعادة بناء المشروع — فقط تتغيّر متغيّرات البيئة ورابط الـ API.

---

## البنية (Monorepo)

```
.
├── backend/            # FastAPI + SQLAlchemy(async) + Alembic + PostgreSQL
│   ├── app/            #   auth, listings, categories, favorites, messages, admin
│   ├── alembic/        #   المهاجرات (migrations)
│   ├── scripts/        #   entrypoint + backup
│   └── tests/          #   اختبارات
├── mobile/             # تطبيق Flutter (RTL عربي، ثيم داكن)
├── nginx/              # الوكيل العكسي (يخدم /media ويمرّر /api)
├── docker-compose.yml  # api + db + nginx (+ minio اختياري)
├── .env.example        # كل الإعدادات عبر متغيّرات البيئة
└── docs/DEPLOYMENT.md  # دليل النشر: Raspberry Pi → VPS + Cloudflare + HTTPS + Backup
```

## المكوّنات التقنية

| الطبقة | التقنية |
|-------|---------|
| التطبيق | Flutter (Material 3, RTL، ثيم داكن/فاتح، خط Tajawal) + Dio + Provider + secure storage |
| الـ API | FastAPI (Python 3.11) + Uvicorn |
| قاعدة البيانات | PostgreSQL 16 عبر SQLAlchemy 2 (async) + مهاجرات Alembic |
| التخزين | ملفات محلية (افتراضي) أو **MinIO/S3** بتبديل متغيّر واحد |
| الحاويات | Docker + docker-compose، وNginx كوكيل عكسي |

## المميزات

- 🔐 حسابات: تسجيل/دخول، جلسة دائمة، تحديث توكن تلقائي.
- 🗂️ أقسام (تُدار من لوحة الإدارة) + 18 محافظة عراقية + تسعير بالدينار.
- 📋 إعلانات: إنشاء/تعديل/حذف، صور متعددة، حالة (نشط/مباع/مخفي)، عدّاد مشاهدات.
- 🔎 بحث وفلترة: نص + قسم + محافظة + سعر + ترتيب.
- ❤️ مفضلة، 💬 محادثات بين البائع والمشتري، 👤 ملف شخصي وإعلاناتي.
- 🛡️ لوحة إدارة (`/api/admin`): إحصاءات، إدارة المستخدمين (حظر/أدوار)، حذف إعلانات، إدارة الأقسام.

## الأمان

Argon2id لكلمات المرور · JWT (Access/Refresh مع تدوير) · Rate Limiting (slowapi) ·
تحقّق مدخلات (Pydantic) · رفع صور آمن (إعادة ترميز عبر Pillow) · أدوار وصلاحيات ·
نسخ احتياطي (pg_dump + الصور) · سجلّات · تشغيل بحاوية بمستخدم غير جذر.

---

## التشغيل السريع (خادم)

```bash
cp .env.example .env      # عدّل SECRET_KEY وكلمات المرور و PUBLIC_BASE_URL
docker compose up -d --build
# الـ API:    http://localhost:8080/api
# التوثيق:    http://localhost:8080/api/docs
```
يقوم الإقلاع تلقائياً بـ: انتظار قاعدة البيانات ← تطبيق المهاجرات ← بذر الأقسام وحساب المدير ← تشغيل الـ API.

## تشغيل التطبيق

```bash
cd mobile
flutter create .          # مرّة واحدة لتوليد مجلدات المنصّات (لا يمسّ lib/)
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   # محاكي أندرويد
```

## الاختبارات (Backend)

```bash
cd backend
pip install -r requirements-dev.txt
pytest
```

## من الراسبيري إلى VPS
راجع **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** — يشمل Cloudflare Tunnel وHTTPS وترحيل البيانات والنسخ الاحتياطي.
