# حزم جاهزة للتثبيت — Souqna Builds

| الملف | الوصف |
|---|---|
| `souqna-release.apk` | تطبيق أندرويد جاهز للتثبيت (Android 5.0+) |
| `souqna-release.apk.sha1` | بصمة التحقق |

## التثبيت على أندرويد
1. انقل ملف `souqna-release.apk` إلى الهاتف وافتحه (فعّل «تثبيت من مصادر غير معروفة» إذا طُلب).
2. **هذه النسخة موقّعة بمفتاح تجريبي (debug)** — مناسبة للتجربة والتوزيع الداخلي، وليست للنشر على Google Play. للنشر أنشئ Keystore خاصاً واضبط `android/key.properties`.
3. النسخة الافتراضية تتصل بـ `http://10.0.2.2:8080` (محاكي أندرويد ← جهازك). لتوجيهها لخادمك أعد البناء:

```bash
cd mobile
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.50:8080
# أو دومينك:
flutter build apk --release --dart-define=API_BASE_URL=https://souqna.example.com
```
