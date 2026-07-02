# سوقنا — تطبيق Flutter

واجهة المستخدم لتطبيق «سوقنا» للبيع والشراء. يتصل بالـ Backend (FastAPI) عبر REST،
ولا يحتوي أي بيانات وهمية — كل شيء يأتي من الخادم.

## أول تشغيل

هذه الحزمة تحتوي كود `lib/` كاملاً، ومجلد **iOS جاهز ومضبوط** داخل المستودع.
لتوليد مجلد أندرويد شغّل مرّة واحدة:

```bash
cd mobile
flutter create . --platforms=android --org iq.souqna   # يولّد android/ دون المساس بـ lib/ أو ios/
flutter pub get
```

بعدها فعّل صلاحية الإنترنت لنسخة الإصدار على أندرويد بإضافة السطر التالي إلى
`android/app/src/main/AndroidManifest.xml` (داخل وسم `<manifest>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
واضبط في `android/app/build.gradle`:  `minSdkVersion 21` (مطلوب لـ flutter_secure_storage).

## تطبيق الآيفون (iOS) 🍎

مجلد `ios/` مضمّن في المستودع ومضبوط مسبقاً:

- اسم التطبيق على الشاشة: **سوقنا**، ومعرّف الحزمة: `iq.souqna.app`.
- أذونات مكتبة الصور والكاميرا (لرفع صور الإعلانات) بنصوص عربية.
- استثناء ATS يسمح بالاتصال بخادم HTTP محلي أثناء التجربة
  (احذف مفتاح `NSAppTransportSecurity` من `ios/Runner/Info.plist` عند النشر بدومين HTTPS).
- `Podfile` جاهز بحد أدنى iOS 13.

البناء يتطلب جهاز macOS مع Xcode (شرط من Apple لكل تطبيقات iOS):

```bash
cd mobile
flutter pub get
cd ios && pod install && cd ..

# تشغيل على محاكي/جهاز آيفون
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080

# ملاحظة: محاكي iOS يصل لجهازك المحلي عبر localhost مباشرة
flutter run --dart-define=API_BASE_URL=http://localhost:8080

# إصدار للنشر (يتطلب حساب Apple Developer للتوقيع)
flutter build ipa --release --dart-define=API_BASE_URL=https://souqna.example.com
```

لتوقيع التطبيق وتشغيله على جهاز حقيقي: افتح `ios/Runner.xcworkspace` في Xcode
واختر فريقك في Signing & Capabilities مرة واحدة.

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

- خط **Cairo** العربي مضمّن محلياً (`assets/fonts/`، رخصة OFL) بخمسة أوزان.
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
