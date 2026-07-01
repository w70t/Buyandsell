/// App configuration.
///
/// The API base URL is injected at build/run time so the SAME binary works
/// against a Raspberry Pi on the LAN, a Cloudflare Tunnel, or a production
/// domain — no code change, no rebuild logic:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080
///   flutter build apk --dart-define=API_BASE_URL=https://souqna.example.com
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080', // Android emulator -> host machine
  );

  static String get apiPrefix => '$apiBaseUrl/api';

  static const String appName = 'سوقنا';
}
