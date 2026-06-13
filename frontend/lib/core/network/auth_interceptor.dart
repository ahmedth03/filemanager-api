import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../storage/secure_storage.dart';

/// JWT auth interceptor that:
/// 1. Injects the `Authorization: Bearer <token>` header on every request.
/// 2. Attempts a silent token refresh when a 401 response is received.
/// 3. Retries the original request exactly once with the new token.
/// 4. Clears tokens and signals logout if the refresh also fails.
class AuthInterceptor extends QueuedInterceptorsWrapper {
  AuthInterceptor({
    required SecureStorage secureStorage,
    required Dio dio,
    this.onLogout,
  })  : _storage = secureStorage,
        _dio = dio;

  final SecureStorage _storage;
  final Dio _dio;

  /// Called when both the original request and the token refresh fail with 401.
  /// Consumers should use this to navigate to the login screen.
  final VoidCallback? onLogout;

  // Flag to prevent multiple concurrent refresh attempts
  bool _isRefreshing = false;

  // ── Request ────────────────────────────────────────────────────────────────

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for public endpoints
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  // ── Response ──────────────────────────────────────────────────────────────

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final request = err.requestOptions;

    // Only handle 401 Unauthorized
    if (response?.statusCode != 401) {
      return handler.next(err);
    }

    // Avoid infinite loop on the refresh endpoint itself
    if (request.path.contains(ApiConfig.refreshToken)) {
      await _handleForcedLogout();
      return handler.next(err);
    }

    // Prevent concurrent refresh calls
    if (_isRefreshing) {
      await _handleForcedLogout();
      return handler.next(err);
    }

    _isRefreshing = true;

    try {
      final newAccessToken = await _refreshToken();
      _isRefreshing = false;

      if (newAccessToken == null) {
        await _handleForcedLogout();
        return handler.next(err);
      }

      // Retry original request with the new token
      request.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch(request);
      return handler.resolve(retryResponse);
    } catch (_) {
      _isRefreshing = false;
      await _handleForcedLogout();
      return handler.next(err);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String?> _refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response = await _dio.post<Map<String, dynamic>>(
      ApiConfig.refreshToken,
      data: {'refresh_token': refreshToken},
      options: Options(
        headers: {'Authorization': null}, // no auth header on refresh call
        extra: {'skipAuthInterceptor': true},
      ),
    );

    final data = response.data;
    if (data == null) return null;

    final newAccessToken = data['access_token'] as String?;
    final newRefreshToken = data['refresh_token'] as String?;

    if (newAccessToken == null) return null;

    await _storage.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken ?? refreshToken,
    );

    return newAccessToken;
  }

  Future<void> _handleForcedLogout() async {
    await _storage.clearAuthData();
    onLogout?.call();
  }

  /// Returns [true] for endpoints that should NOT have an auth header.
  static bool _isPublicEndpoint(String path) {
    const publicPaths = {
      ApiConfig.login,
      ApiConfig.register,
      ApiConfig.refreshToken,
      ApiConfig.forgotPassword,
      ApiConfig.resetPassword,
      ApiConfig.verifyPhone,
      ApiConfig.resendOtp,
      ApiConfig.appVersion,
      ApiConfig.appConfig,
      ApiConfig.termsOfService,
      ApiConfig.privacyPolicy,
      ApiConfig.wilayas,
      ApiConfig.communes,
    };
    return publicPaths.any((p) => path.endsWith(p) || path.contains(p));
  }
}
