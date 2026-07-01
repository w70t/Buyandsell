# سوق العراق — Iraq Souq 🛒

تطبيق أندرويد كامل للبيع والشراء في العراق، بأسلوب مشابه لتطبيق **Kleinanzeigen**.
مبني بالكامل من الصفر باستخدام **Kotlin + Jetpack Compose + Room**، مع دعم كامل
للغة العربية والاتجاه من اليمين إلى اليسار (RTL)، والمحافظات العراقية، وعملة الدينار العراقي.

A complete native Android marketplace app for Iraq, inspired by Kleinanzeigen —
built from scratch with Kotlin, Jetpack Compose, and Room. Full Arabic/RTL UI,
the 18 Iraqi governorates, and Iraqi Dinar pricing.

---

## المميزات / Features

- 🔐 **الحسابات**: تسجيل حساب جديد وتسجيل الدخول (يُحفظ محلياً مع بقاء الجلسة).
- 🏠 **الرئيسية**: الأقسام + أحدث الإعلانات.
- 🔎 **البحث والفلترة**: بحث نصي + فلترة حسب القسم والمحافظة.
- 🗂️ **الأقسام**: سيارات، هواتف، إلكترونيات، عقارات، أثاث، أزياء، وظائف، حيوانات، مستلزمات أطفال، وغيرها.
- 📸 **إضافة إعلان**: عنوان، وصف، سعر، قابلية التفاوض، قسم، محافظة، وصور متعددة من الجهاز.
- ❤️ **المفضلة**: حفظ الإعلانات المفضّلة.
- 💬 **المحادثات**: مراسلة البائع داخل التطبيق (محادثات محلية) + زر اتصال مباشر.
- 👤 **الملف الشخصي**: إعلاناتي، المفضلة، تسجيل الخروج.
- 🌍 دعم كامل للعربية و RTL، و **18 محافظة عراقية**، وتسعير بالدينار العراقي.

## البنية التقنية / Tech Stack

| الطبقة | التقنية |
|-------|---------|
| اللغة | Kotlin 2.0 |
| واجهة المستخدم | Jetpack Compose (Material 3) |
| التنقّل | Navigation Compose |
| قاعدة البيانات | Room (SQLite) |
| الجلسة/التفضيلات | DataStore |
| تحميل الصور | Coil |
| النمط المعماري | MVVM (ViewModel + StateFlow + Repository) |

## هيكل المشروع / Project structure

```
app/src/main/java/com/iraqsouq/app/
├── MarketApp.kt            # Application + حاوية الاعتماديات
├── MainActivity.kt         # نقطة الدخول + فرض RTL + الثيم
├── model/StaticData.kt     # الأقسام + المحافظات العراقية
├── data/                   # Room: Entities, DAOs, Database, Repository, Session, Seed
└── ui/
    ├── MainViewModel.kt    # حالة التطبيق (auth, listings, favorites, chat)
    ├── theme/              # ألوان وثيم Material 3
    ├── components/         # ListingCard, TopBar
    ├── nav/                # Routes + AppRoot (Scaffold + BottomNav + NavHost)
    └── screens/            # Auth, Home, Search, Category, Detail, PostAd,
                            #   MyAds, Favorites, Chats, Chat, Profile
```

## البناء والتشغيل / Build & Run

يتطلّب **Android Studio** (أحدث إصدار) أو حزمة Android SDK مع JDK 17.

1. افتح المجلد في Android Studio (`File → Open`).
2. اترك Gradle يزامن الاعتماديات.
3. شغّل التطبيق على محاكي أو جهاز حقيقي (Android 7.0 / API 24 فأحدث).

من سطر الأوامر (يتطلّب ضبط `ANDROID_HOME` ووجود ملف `local.properties`):

```bash
./gradlew assembleDebug        # إنشاء APK للتجربة
./gradlew installDebug         # التثبيت على جهاز متصل
```

> ملاحظة: عند أول تشغيل تُضاف إعلانات تجريبية تلقائياً لتظهر الواجهة عامرة.
> لنشر إعلان أو المراسلة، أنشئ حساباً من شاشة "حسابي".

## خارطة طريق مقترحة / Suggested next steps

- ربط بخادم حقيقي (REST/Firebase) بدل التخزين المحلي.
- إشعارات فورية للرسائل.
- تحديد الموقع على الخريطة داخل الإعلان.
- التحقق من رقم الهاتف عبر OTP.
