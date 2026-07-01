import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// إعدادات التطبيق (وضع الثيم) مع حفظ دائم.
class SettingsProvider extends ChangeNotifier {
  static const _kThemeMode = 'settings.theme_mode';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode != ThemeMode.light;

  Future<void> load() async {
    try {
      final v = await _storage.read(key: _kThemeMode);
      if (v == 'light') _themeMode = ThemeMode.light;
      if (v == 'dark') _themeMode = ThemeMode.dark;
    } catch (_) {
      // نُبقي الافتراضي إن تعذّرت القراءة.
    }
    notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      await _storage.write(key: _kThemeMode, value: dark ? 'dark' : 'light');
    } catch (_) {}
  }
}
