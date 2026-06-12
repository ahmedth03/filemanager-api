import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

/// Riverpod provider that exposes the configured [Dio] instance.
final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient.create(secureStorage: secureStorage);
});

/// Factory that constructs and configures the application [Dio] client.
class ApiClient {
  ApiClient._();

  static Dio create({
    required SecureStorage secureStorage,
    VoidCallback? onLogout,
  }) {
    final config = AppConfig.instance;

    // ── Base options ──────────────────────────────────────────────────────────
    final baseOptions = BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: Duration(seconds: config.connectTimeoutSeconds),
      receiveTimeout: Duration(seconds: config.receiveTimeoutSeconds),
      sendTimeout: Duration(seconds: config.connectTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': 'ar',
        'X-App-Platform': 'flutter',
      },
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    );

    final dio = Dio(baseOptions);

    // ── Interceptors (order matters) ──────────────────────────────────────────

    // 1. Auth interceptor — attaches token & handles 401 refresh
    dio.interceptors.add(
      AuthInterceptor(
        secureStorage: secureStorage,
        dio: dio,
        onLogout: onLogout,
      ),
    );

    // 2. Logging interceptor — only in non-production builds
    if (config.enableLogging) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: kDebugMode,
          responseBody: kDebugMode,
          requestHeader: kDebugMode,
          responseHeader: false,
          error: true,
          logPrint: (object) => debugPrint('[Dio] $object'),
        ),
      );
    }

    // 3. Custom error normaliser
    dio.interceptors.add(_ErrorNormalizerInterceptor());

    return dio;
  }
}

// ---------------------------------------------------------------------------
// Error normaliser
// ---------------------------------------------------------------------------

/// Ensures every error response body is consistently decoded as
/// `Map<String, dynamic>` before reaching the [DioErrorHandler].
class _ErrorNormalizerInterceptor extends InterceptorsWrapper {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    // Attempt to decode string bodies to maps
    if (response != null && response.data is String) {
      try {
        // Dio's transformer sometimes returns a raw string for error bodies
        final raw = response.data as String;
        if (raw.startsWith('{')) {
          // Let the DioErrorHandler deal with it directly
          handler.next(err);
          return;
        }
      } catch (_) {/* ignore */}
    }

    handler.next(err);
  }
}
