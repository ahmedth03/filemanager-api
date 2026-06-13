import 'package:dio/dio.dart';

import '../../domain/repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// AuthRemoteDataSource – abstract interface
// ---------------------------------------------------------------------------
abstract interface class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  });

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    required String userType,
    String? wilaya,
  });

  Future<void> logout();

  Future<Map<String, dynamic>> getCurrentUser();

  Future<String> refreshToken(String refreshToken);

  Future<void> forgotPassword(String phone);

  Future<String> verifyOtp({required String phone, required String otp});

  Future<void> resetPassword({required String token, required String newPassword});

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data);
}

// ---------------------------------------------------------------------------
// AuthRemoteDataSourceImpl
// ---------------------------------------------------------------------------
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  // Endpoint constants
  static const String _login = '/auth/login';
  static const String _register = '/auth/register';
  static const String _logout = '/auth/logout';
  static const String _me = '/auth/me';
  static const String _refresh = '/auth/refresh';
  static const String _forgot = '/auth/forgot-password';
  static const String _verifyOtp = '/auth/verify-otp';
  static const String _resetPassword = '/auth/reset-password';
  static const String _updateProfile = '/auth/profile';

  @override
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _login,
        data: {'phone': phone, 'password': password},
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    required String userType,
    String? wilaya,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _register,
        data: {
          'name': name,
          'phone': phone,
          'password': password,
          'user_type': userType,
          if (wilaya != null) 'wilaya': wilaya,
        },
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<void>(_logout);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_me);
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _refresh,
        data: {'refresh_token': refreshToken},
      );
      final data = _extractData(response);
      final token = data['access_token'] as String?;
      if (token == null) {
        throw const ServerException('No access token in refresh response.');
      }
      return token;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> forgotPassword(String phone) async {
    try {
      await _dio.post<void>(
        _forgot,
        data: {'phone': phone},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<String> verifyOtp({required String phone, required String otp}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _verifyOtp,
        data: {'phone': phone, 'otp': otp},
      );
      final data = _extractData(response);
      final token = data['reset_token'] as String?;
      if (token == null) {
        throw const ServerException('No reset token in OTP response.');
      }
      return token;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post<void>(
        _resetPassword,
        data: {'token': token, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        _updateProfile,
        data: data,
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  Map<String, dynamic> _extractData(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) {
      throw const ServerException('Empty response from server.');
    }
    // Support both `{ "data": {...} }` and flat `{ ... }` responses
    if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    return body;
  }

  AuthException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return const UnauthorizedException();
        }
        if (statusCode == 409) {
          return const PhoneAlreadyExistsException();
        }
        if (statusCode == 422 || statusCode == 400) {
          final msg = _extractErrorMessage(e.response?.data) ??
              'Invalid request. Please check your input.';
          return InvalidCredentialsException(msg);
        }
        final serverMsg = _extractErrorMessage(e.response?.data);
        return ServerException(serverMsg ?? 'Server error (${statusCode ?? 'unknown'}).');
      default:
        return const NetworkException();
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['message'] ?? data['error'] ?? data['msg']) as String?;
    }
    return null;
  }
}
