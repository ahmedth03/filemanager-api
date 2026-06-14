import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _create();
    return _instance!;
  }

  static void reset() {
    _instance = null;
  }

  static Dio _create() {
    final config = AppConfig.instance;
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: Duration(milliseconds: config.connectionTimeout),
        receiveTimeout: Duration(milliseconds: config.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (config.enableLogging) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              final refreshToken = await SecureStorage.getRefreshToken();
              if (refreshToken == null || refreshToken.isEmpty) {
                await SecureStorage.clearAll();
                handler.next(error);
                return;
              }

              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: AppConfig.instance.apiBaseUrl,
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                ),
              );

              final refreshResponse = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );

              final data = refreshResponse.data['data'] ?? refreshResponse.data;
              final newAccessToken = data['accessToken'] as String?;
              final newRefreshToken = data['refreshToken'] as String?;

              if (newAccessToken == null) {
                await SecureStorage.clearAll();
                handler.next(error);
                return;
              }

              await SecureStorage.saveToken(newAccessToken);
              if (newRefreshToken != null) {
                await SecureStorage.saveRefreshToken(newRefreshToken);
              }

              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await dio.fetch(retryOptions);
              handler.resolve(retryResponse);
            } catch (_) {
              await SecureStorage.clearAll();
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
        },
      ),
    );

    return dio;
  }

  // Keep for backward compat – sets the in-memory token (auth repo calls this after login)
  static Future<void> setToken(String token) async {
    await SecureStorage.saveToken(token);
  }

  static Future<void> clearToken() async {
    await SecureStorage.clearAll();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('انتهت مهلة الاتصال. تحقق من الإنترنت.');
      case DioExceptionType.connectionError:
        return const ApiException('تعذر الاتصال بالخادم. تأكد من تشغيل الخادم.');
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        final msg = data is Map
            ? (data['message'] ?? data['error'] ?? 'خطأ من الخادم')
            : 'خطأ من الخادم';
        return ApiException(msg.toString(), statusCode: e.response?.statusCode);
      default:
        return ApiException(e.message ?? 'خطأ غير معروف');
    }
  }

  @override
  String toString() => message;
}
