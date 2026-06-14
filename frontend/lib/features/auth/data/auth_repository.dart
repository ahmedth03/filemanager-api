import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'models/auth_models.dart';

class AuthRepository {
  final Dio _dio = DioClient.instance;

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/auth/login', data: request.toJson());
      final auth = AuthResponse.fromJson(response.data['data'] ?? response.data);
      await _persist(auth);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response =
          await _dio.post('/auth/register', data: request.toJson());
      final auth = AuthResponse.fromJson(response.data['data'] ?? response.data);
      await _persist(auth);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await SecureStorage.clearAll();
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final auth = AuthResponse.fromJson(response.data['data'] ?? response.data);
      await _persist(auth);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel?> getStoredUser() async {
    final json = await SecureStorage.getUser();
    if (json == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _persist(AuthResponse auth) async {
    await SecureStorage.saveToken(auth.accessToken);
    await SecureStorage.saveRefreshToken(auth.refreshToken);
    await SecureStorage.saveUser(jsonEncode(auth.user.toJson()));
  }
}
