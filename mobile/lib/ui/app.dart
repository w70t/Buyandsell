import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../state/auth_provider.dart';
import '../state/favorites_provider.dart';
import '../state/settings_provider.dart';
import 'screens/home_shell.dart';

class SouqnaApp extends StatefulWidget {
  const SouqnaApp({super.key});

  @override
  State<SouqnaApp> createState() => _SouqnaAppState();
}

class _SouqnaAppState extends State<SouqnaApp> {
  @override
  void initState() {
    super.initState();
    // Boot settings + session, then load favorites if signed in.
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final favorites = context.read<FavoritesProvider>();
    Future.microtask(() async {
      await settings.load();
      await auth.bootstrap();
      if (auth.isLoggedIn) {
        await favorites.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode =
        context.select<SettingsProvider, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const _Gate(),
    );
  }
}

/// يعرض شاشة الانطلاق أثناء تهيئة الجلسة ثم ينتقل بسلاسة للتطبيق.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final booting = context.select<AuthProvider, bool>((a) => a.booting);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: booting ? const SplashScreen() : const HomeShell(),
    );
  }
}

/// شاشة انطلاق بهوية العلامة مع حركة ظهور ناعمة.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween<double>(begin: 0.82, end: 1)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 60,
                      color: AppTheme.brandDark,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'سوقنا',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'بيع واشترِ كل شيء بالقرب منك',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
