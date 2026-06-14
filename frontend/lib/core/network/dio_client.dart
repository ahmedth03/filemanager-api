import 'package:dio/dio.dart';
import '../config/app_config.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _create();
    return _instance!;
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
        onRequest: (options, handler) {
          final token = _authToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static String? _authToken;

  static void setToken(String token) {
    _authToken = token;
  }

  static void clearToken() {
    _authToken = null;
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
        final msg = data is Map ? (data['message'] ?? data['error'] ?? 'خطأ من الخادم') : 'خطأ من الخادم';
        return ApiException(msg.toString(), statusCode: e.response?.statusCode);
      default:
        return ApiException(e.message ?? 'خطأ غير معروف');
    }
  }

  @override
  String toString() => message;
}
