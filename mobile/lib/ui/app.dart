import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../state/auth_provider.dart';
import '../state/favorites_provider.dart';
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
    // Boot the session, then load favorites if signed in.
    Future.microtask(() async {
      final auth = context.read<AuthProvider>();
      await auth.bootstrap();
      if (auth.isLoggedIn) {
        await context.read<FavoritesProvider>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
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

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final booting = context.select<AuthProvider, bool>((a) => a.booting);
    if (booting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const HomeShell();
  }
}
