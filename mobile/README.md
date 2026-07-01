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

## نظام التصميم

- خط **Tajawal** العربي مضمّن محلياً (`assets/fonts/`، رخصة OFL) بأربعة أوزان.
- ثيمان كاملان **داكن وفاتح** يتبدّلان من شاشة «حسابي» ويُحفظ الاختيار.
- كل الألوان عبر امتداد ثيم `SxColors` — الوصول من أي شاشة بـ `context.sx`.
- هياكل تحميل (Shimmer skeletons) بلا أي حزم إضافية، حالات فارغة برسائل وأزرار،
  شارات حالة (جديد/مُباع/نشط)، وتمرير لا نهائي في الرئيسية والبحث والأقسام.
- شاشة انطلاق متحركة بهوية العلامة، وفواصل أيام وفقاعات بأوقات في المحادثة.

## البنية

```
lib/
├── main.dart               # التهيئة وحقن مزوّدي الحالة
├── core/                   # الإعداد، الثيم (SxColors)، عميل API، التخزين الآمن، التنسيقات
├── models/                 # نماذج البيانات (JSON)
├── services/api_service.dart  # كل نداءات الـ API
├── state/                  # Auth + Favorites + Settings (الثيم)
├── data/governorates.dart  # المحافظات العراقية الـ 18
└── ui/
    ├── app.dart            # MaterialApp + RTL عربي + شاشة الانطلاق + الثيمان
    ├── navigation.dart     # مساعدات التنقل
    ├── widgets/            # بطاقة الإعلان، الشبكة الموحّدة، الهياكل، الحالات الفارغة
    └── screens/            # كل الشاشات (رئيسية، بحث، تفاصيل، نشر، مفضلة، محادثات، حساب…)
```
