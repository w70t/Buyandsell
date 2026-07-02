# الترحيل من Raspberry Pi إلى VPS / سحابة — بدون إعادة بناء

المبدأ: الكود والحاويات **لا يتغيّران**. ينتقل ثلاثة أشياء فقط:
**`.env` + نسخة قاعدة البيانات + مجلد الصور**.

## 1) على الراسبيري — خذ نسخة نهائية
```bash
cd souqna
docker compose exec -T db pg_dump -U souqna souqna | gzip > final_db.sql.gz
tar -czf final_uploads.tar.gz -C data uploads
```

## 2) على الـ VPS (Ubuntu/Debian, amd64)
```bash
curl -fsSL https://get.docker.com | sh
git clone <repo-url> souqna && cd souqna
scp pi@<IP-الراسبيري>:~/souqna/final_*.gz .
scp pi@<IP-الراسبيري>:~/souqna/.env .
```
حدّث `.env` للقيم الجديدة:
```
PUBLIC_BASE_URL=https://souqna.example.com
COOKIE_SECURE=true
UVICORN_WORKERS=4            # حسب أنوية الخادم
REDIS_URL=redis://redis:6379/0   # عند استخدام أكثر من worker
```

## 3) استعادة البيانات ثم الإقلاع
```bash
mkdir -p data && tar -xzf final_uploads.tar.gz -C data
sudo chown -R 1000:1000 data/uploads
docker compose up -d --build db          # القاعدة أولاً
gunzip -c final_db.sql.gz | docker compose exec -T db psql -U souqna souqna
docker compose --profile redis up -d --build   # ثم كل الخدمات
```
الصورة تُبنى تلقائياً لمعمارية amd64 — نفس Dockerfile الذي بُني على arm64.

## 4) الدومين و HTTPS
الخياران:
- **Cloudflare أمام الخادم** (الأسهل): DNS ⇠ Proxy مفعّل ⇠ SSL "Full". أبقِ 8080 داخلياً
  ووجّه Cloudflare إليه، أو ضع 80/443 مباشرة.
- **Caddy/Certbot على الخادم**: وكيل عكسي أمام `localhost:8080` مع شهادة Let's Encrypt.

بعد تفعيل HTTPS تأكد من `PUBLIC_BASE_URL=https://…` و`COOKIE_SECURE=true` ثم
`docker compose up -d` (روابط الصور تُبنى ديناميكياً فتصبح صحيحة فوراً).

## 5) تحديث تطبيق Flutter
أعد البناء مرة واحدة برابط الإنتاج:
`flutter build apk --dart-define=API_BASE_URL=https://souqna.example.com`

## 6) تحقّق بعد الترحيل
- [ ] `/api/health` يعيد ok، و`/` و`/admin` يعملان.
- [ ] الدخول بحساب قديم يعمل (نفس SECRET_KEY = نفس كلمات المرور تعمل؛ التوكنات القديمة
      تنتهي طبيعياً).
- [ ] صور الإعلانات القديمة تظهر (المفاتيح نُقلت والروابط تُبنى من الدومين الجديد).
- [ ] البحث والمحادثات والإشعارات تعمل ببيانات ما قبل الترحيل.
- [ ] فعّل cron النسخ الاحتياطي على الخادم الجديد.

## التوسّع لاحقاً على السحابة (بلا تغيير كود)
| الحاجة | الخطوة |
|---|---|
| قاعدة مُدارة (RDS/DO) | `DATABASE_URL` إلى القاعدة المُدارة + استعادة الدمب |
| تخزين سحابي للصور | `STORAGE_BACKEND=minio` مع endpoint/credentials خدمة S3 |
| عدة خوادم API | نفس الصورة خلف Load Balancer + Redis مشترك — الحالة كلها خارج العملية |

## خطة التراجع (Rollback)
أبقِ الراسبيري يعمل حتى يستقر الـ VPS؛ التراجع = إعادة توجيه DNS إليه فقط.
لا تكتب على القاعدتين في آن واحد.
