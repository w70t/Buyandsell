# النشر على Raspberry Pi 5 (8GB) — خطوة بخطوة

نفس الحاويات ستعمل لاحقاً على VPS دون إعادة بناء المشروع — انظر `MIGRATION_TO_VPS.md`.

## 0) المتطلبات
- Raspberry Pi 5 (8GB) + بطاقة SD سريعة أو **SSD عبر USB3 (موصى به بشدة لقاعدة البيانات)**.
- Raspberry Pi OS Lite **64-bit** (Bookworm).
- اتصال شبكة منزلي بعنوان IP ثابت للراسبيري (احجزه من الراوتر).

## 1) تثبيت Docker
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER    # أعد تسجيل الدخول بعدها
docker --version && docker compose version
```

## 2) جلب المشروع وضبط البيئة
```bash
git clone <repo-url> souqna && cd souqna
cp .env.example .env
nano .env
```
غيّر على الأقل:
```
SECRET_KEY=$(openssl rand -hex 32)
POSTGRES_PASSWORD=<قوية>
DATABASE_URL=postgresql+asyncpg://souqna:<نفس-كلمة-المرور>@db:5432/souqna
ADMIN_PASSWORD=<قوية>
PUBLIC_BASE_URL=http://<IP-الراسبيري>:8080
```

## 3) تجهيز مجلد الصور ثم الإقلاع
```bash
mkdir -p data/uploads && sudo chown -R 1000:1000 data/uploads   # حاوية API تعمل بمستخدم غير جذري (uid 1000)
docker compose up -d --build
docker compose logs -f api   # انتظر: migrations ⇠ seed ⇠ "API starting"
```

## 4) تحقق
- الموقع: `http://<IP>:8080` — لوحة الإدارة: `/admin` (هاتف/كلمة مرور المدير من `.env`).
- التوثيق: `/api/docs` — الصحة: `/api/health`.
- تطبيق Flutter: `flutter run --dart-define=API_BASE_URL=http://<IP>:8080`.

## 5) نسخ احتياطي يومي (cron)
```bash
crontab -e
# 0 3 * * * /home/pi/souqna/backend/scripts/backup.sh >> /var/log/souqna-backup.log 2>&1
```
انسخ مجلد `backups/` دورياً إلى مكان خارج الراسبيري (قرص خارجي / سحابة).

## 6) الوصول من الإنترنت (اختياري وآمن)
الأفضل بلا فتح منافذ: **Cloudflare Tunnel**
```bash
# على الراسبيري
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o cloudflared
sudo install cloudflared /usr/local/bin/
cloudflared tunnel login && cloudflared tunnel create souqna
# وجّه الدومين إلى http://localhost:8080 في config.yml ثم:
sudo cloudflared service install
```
ثم حدّث `.env`: `PUBLIC_BASE_URL=https://souqna.example.com` و`COOKIE_SECURE=true`
وأعد التشغيل: `docker compose up -d`.

## 7) ملاحظات أداء للراسبيري
- `UVICORN_WORKERS=1` (الافتراضي) كافٍ للتجربة؛ ارفعه لاحقاً على VPS.
- أبقِ Postgres على SSD وليس بطاقة SD (عمر البطاقة + سرعة).
- خدمات redis/minio الاختيارية غير ضرورية هنا — لا تشغّلها لتوفير الذاكرة.
- المراقبة السريعة: `docker stats` و`docker compose logs -f`.

## استكشاف الأخطاء
| العرض | السبب/الحل |
|---|---|
| `PermissionError /data/uploads` | نفّذ `sudo chown -R 1000:1000 data/uploads` |
| api يعيد التشغيل | `docker compose logs api` — غالباً DATABASE_URL/كلمة مرور غير متطابقة |
| صور لا تظهر | تأكد أن `PUBLIC_BASE_URL` يطابق العنوان الذي يفتح منه المستخدمون |
