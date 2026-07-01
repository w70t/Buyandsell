# سوقنا — تطبيق Flutter

واجهة المستخدم لتطبيق «سوقنا» للبيع والشراء. يتصل بالـ Backend (FastAPI) عبر REST،
ولا يحتوي أي بيانات وهمية — كل شيء يأتي من الخادم.

## أول تشغيل

هذه الحزمة تحتوي كود `lib/` كاملاً. لتوليد مجلدات المنصّات (android/ios) شغّل مرّة واحدة:

```bash
cd mobile
flutter create .          # يولّد android/ و ios/ دون المساس بـ lib/
flutter pub get
```

بعدها فعّل صلاحية الإنترنت لنسخة الإصدار على أندرويد بإضافة السطر التالي إلى
`android/app/src/main/AndroidManifest.xml` (داخل وسم `<manifest>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
واضبط في `android/app/build.gradle`:  `minSdkVersion 21` (مطلوب لـ flutter_secure_storage).

## التشغيل مع رابط الخادم

عنوان الـ API يُحقن وقت التشغيل عبر `--dart-define` — نفس التطبيق يعمل على الراسبيري ثم على الدومين دون إعادة بناء المنطق:

```bash
# محاكي أندرويد يتصل بجهازك المحلي (الافتراضي 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# جهاز حقيقي على نفس شبكة الراسبيري
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080

# إصدار للإنتاج مع دومين وHTTPS
flutter build apk --release --dart-define=API_BASE_URL=https://souqna.example.com
```

## البنية

```
lib/
├── main.dart               # التهيئة وحقن مزوّدي الحالة
├── core/                   # الإعداد، الثيم، عميل API (تحديث التوكن)، التخزين الآمن
├── models/                 # نماذج البيانات (JSON)
├── services/api_service.dart  # كل نداءات الـ API
├── state/                  # AuthProvider + FavoritesProvider
├── data/governorates.dart  # المحافظات العراقية
└── ui/
    ├── app.dart            # MaterialApp + RTL عربي + الثيم الداكن
    ├── navigation.dart     # مساعدات التنقل
    └── screens/            # كل الشاشات (رئيسية، بحث، تفاصيل، نشر، مفضلة، محادثات، حساب…)
```
