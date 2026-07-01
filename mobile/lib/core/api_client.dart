import 'package:dio/dio.dart';

import 'config.dart';
import 'token_store.dart';

/// Thin wrapper around Dio that:
///  - attaches the access token to every request,
///  - transparently refreshes it once on a 401 and retries,
///  - surfaces friendly Arabic error messages.
class ApiClient {
  ApiClient(this.tokens) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiPrefix,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    _refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiPrefix));
    dio.interceptors.add(_authInterceptor());
  }

  final TokenStore tokens;
  late final Dio dio;
  late final Dio _refreshDio;

  /// Called when refresh fails (session expired) so the app can log out.
  void Function()? onSessionExpired;

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokens.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final response = error.response;
        final isAuthPath = error.requestOptions.path.contains('/auth/');
        if (response?.statusCode == 401 &&
            tokens.refreshToken != null &&
            !isAuthPath &&
            error.requestOptions.extra['retried'] != true) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final req = error.requestOptions;
            req.extra['retried'] = true;
            req.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
            try {
              final clone = await dio.fetch(req);
              return handler.resolve(clone);
            } catch (e) {
              return handler.next(error);
            }
          } else {
            onSessionExpired?.call();
          }
        }
        handler.next(error);
      },
    );
  }

  Future<bool> _tryRefresh() async {
    try {
      final res = await _refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': tokens.refreshToken},
      );
      await tokens.save(
        access: res.data['access_token'] as String,
        refresh: res.data['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Extracts the API's `detail` message from a DioException.
String apiErrorMessage(Object error, [String fallback = 'حدث خطأ، حاول مجدداً']) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    if (data is Map && data['detail'] is List && (data['detail'] as List).isNotEmpty) {
      final first = (data['detail'] as List).first;
      if (first is Map && first['msg'] is String) return first['msg'] as String;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'تعذّر الاتصال بالخادم';
    }
  }
  return fallback;
}
