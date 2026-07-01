# دليل النشر — من Raspberry Pi إلى VPS

الفكرة الأساسية: **نفس حاويات Docker تعمل على الراسبيري ثم على الـ VPS**، ولا يتغيّر
سوى ملف `.env` ورابط الـ API في التطبيق. لا إعادة بناء للمشروع.

---

## 1) التشغيل على Raspberry Pi (تجريبي داخل البيت)

المتطلبات: Raspberry Pi (يفضّل 4/5 بذاكرة 2GB+) مع Raspberry Pi OS 64-bit، و Docker.

```bash
# تثبيت Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # ثم أعد تسجيل الدخول

# جلب المشروع وضبط الإعدادات
git clone <repo-url> souqna && cd souqna
cp .env.example .env
nano .env        # غيّر SECRET_KEY وكلمات المرور، واضبط PUBLIC_BASE_URL=http://<IP-الراسبيري>:8080

# الإقلاع
docker compose up -d --build
docker compose logs -f api      # للاطمئنان أن المهاجرات والبذور تمّت
```

الآن الـ API على `http://<IP-الراسبيري>:8080/api` والتوثيق على `/api/docs`.
التطبيق (Flutter) يتصل هكذا:

```bash
flutter run --dart-define=API_BASE_URL=http://<IP-الراسبيري>:8080
```

### الوصول من خارج البيت بدون IP ثابت — Cloudflare Tunnel

```bash
# على الراسبيري
cloudflared tunnel login
cloudflared tunnel create souqna
cloudflared tunnel route dns souqna souqna.example.com
# وجّه النفق إلى nginx المحلي:
cloudflared tunnel run --url http://localhost:8080 souqna
```
ثم في `.env` اجعل `PUBLIC_BASE_URL=https://souqna.example.com`، وأعد `docker compose up -d`.
التطبيق: `--dart-define=API_BASE_URL=https://souqna.example.com` (HTTPS مجاناً عبر Cloudflare).

---

## 2) الانتقال إلى VPS مع Domain و HTTPS

على الـ VPS نفس الخطوات، مع إضافة شهادة HTTPS. الأسهل إبقاء Cloudflare أمام الخادم،
أو استخدام Caddy/Nginx مع Let's Encrypt:

```bash
# مثال بـ Caddy كوكيل أمامي (HTTPS تلقائي)
# Caddyfile:
#   souqna.example.com {
#       reverse_proxy localhost:8080
#   }
```

خطوات الترحيل من الراسبيري إلى الـ VPS دون فقدان بيانات:

```bash
# على الراسبيري: نسخة احتياطية
./backend/scripts/backup.sh          # ينتج backups/db_*.sql.gz و uploads_*.tar.gz

# انسخ الملفات إلى الـ VPS ثم استعِد:
gunzip -c db_XXXX.sql.gz | docker compose exec -T db psql -U "$POSTGRES_USER" "$POSTGRES_DB"
tar -xzf uploads_XXXX.tar.gz -C data/     # يعيد data/uploads

# حدّث PUBLIC_BASE_URL في .env إلى الدومين، ثم:
docker compose up -d --build
```

> بما أن روابط الصور تُبنى ديناميكياً من `PUBLIC_BASE_URL` + مفتاح التخزين،
> فإن تغيير الدومين لا يكسر الصور القديمة.

### التخزين القابل للتوسّع (MinIO)

للتوسّع، بدّل تخزين الصور إلى كائنات S3 دون تغيير كود:

```bash
# في .env
STORAGE_BACKEND=minio
docker compose --profile minio up -d
```

---

## 3) الأمان (مطبَّق في الـ Backend)

| المتطلب | التطبيق |
|--------|---------|
| تجزئة كلمات المرور | Argon2id (`argon2-cffi`) مع إعادة تجزئة تلقائية |
| المصادقة | JWT: Access قصير + Refresh طويل، مع تدوير عند 401 |
| Rate Limiting | `slowapi` (حدود عامة + حدود أشد على مسارات المصادقة) |
| التحقق من المدخلات | Pydantic v2 + تحقّق أرقام الهواتف العراقية |
| رفع الملفات الآمن | إعادة ترميز الصور عبر Pillow (يمنع الحمولات الخبيثة، يزيل EXIF، يحدّ الأبعاد والحجم) |
| الصلاحيات | أدوار (user/admin) + حراس مسارات، ولوحة إدارة تحت `/api/admin` |
| النسخ الاحتياطي | `scripts/backup.sh` عبر cron (قاعدة البيانات + الصور) |
| السجلّات | تسجيل منظّم إلى stdout (يجمعه Docker) |
| المستخدم غير الجذر | حاوية الـ API تعمل بمستخدم `appuser` |

### إعداد النسخ الاحتياطي التلقائي (cron)

```bash
crontab -e
# نسخة يومية الساعة 3 فجراً
0 3 * * * cd /path/to/souqna && ./backend/scripts/backup.sh >> /var/log/souqna-backup.log 2>&1
```

---

## 4) خطوات ما بعد الإطلاق الموصى بها
- ولّد `SECRET_KEY` قوياً: `openssl rand -hex 32`.
- غيّر `ADMIN_PASSWORD` بعد أول دخول.
- فعّل جدار الحماية (اسمح فقط بـ 80/443 للخارج، وأبقِ 5432/9000 داخلية).
- راقب `docker compose logs` أو اربطها بنظام مراقبة.
