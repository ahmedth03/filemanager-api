import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

// ---------------------------------------------------------------------------
// Local storage interface (simple contract used by the repository)
// ---------------------------------------------------------------------------
abstract interface class AuthLocalStorage {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearAuthData();
  Future<void> setUserId(String id);
}

// ---------------------------------------------------------------------------
// AuthRepositoryImpl
// ---------------------------------------------------------------------------
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalStorage localStorage,
  })  : _remote = remoteDataSource,
        _local = localStorage;

  final AuthRemoteDataSource _remote;
  final AuthLocalStorage _local;

  // ------------------------------------------------------------------
  // login
  // ------------------------------------------------------------------
  @override
  Future<User> login({
    required String phone,
    required String password,
  }) async {
    final data = await _remote.login(phone: phone, password: password);
    await _persistTokens(data);
    return _parseUser(data);
  }

  // ------------------------------------------------------------------
  // register
  // ------------------------------------------------------------------
  @override
  Future<User> register({
    required String name,
    required String phone,
    required String password,
    required UserType userType,
    String? wilaya,
  }) async {
    final data = await _remote.register(
      name: name,
      phone: phone,
      password: password,
      userType: userType.name, // 'client' | 'craftsman' | 'owner'
      wilaya: wilaya,
    );
    await _persistTokens(data);
    return _parseUser(data);
  }

  // ------------------------------------------------------------------
  // logout
  // ------------------------------------------------------------------
  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Always clear local tokens even if the server call fails
    } finally {
      await _local.clearAuthData();
    }
  }

  // ------------------------------------------------------------------
  // getCurrentUser
  // ------------------------------------------------------------------
  @override
  Future<User> getCurrentUser() async {
    final data = await _remote.getCurrentUser();
    return _parseUser(data);
  }

  // ------------------------------------------------------------------
  // refreshToken
  // ------------------------------------------------------------------
  @override
  Future<String> refreshToken() async {
    final storedRefresh = await _local.getRefreshToken();
    if (storedRefresh == null || storedRefresh.isEmpty) {
      throw const UnauthorizedException('No refresh token available.');
    }
    final newToken = await _remote.refreshToken(storedRefresh);
    await _local.saveTokens(
      accessToken: newToken,
      refreshToken: storedRefresh,
    );
    return newToken;
  }

  // ------------------------------------------------------------------
  // forgotPassword
  // ------------------------------------------------------------------
  @override
  Future<void> forgotPassword(String phone) async {
    await _remote.forgotPassword(phone);
  }

  // ------------------------------------------------------------------
  // verifyOtp
  // ------------------------------------------------------------------
  @override
  Future<String> verifyOtp({required String phone, required String otp}) async {
    return _remote.verifyOtp(phone: phone, otp: otp);
  }

  // ------------------------------------------------------------------
  // resetPassword
  // ------------------------------------------------------------------
  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _remote.resetPassword(token: token, newPassword: newPassword);
  }

  // ------------------------------------------------------------------
  // updateProfile
  // ------------------------------------------------------------------
  @override
  Future<User> updateProfile({
    String? name,
    String? email,
    String? bio,
    String? wilaya,
    String? avatarPath,
  }) async {
    final Map<String, dynamic> payload = {};
    if (name != null) payload['name'] = name;
    if (email != null) payload['email'] = email;
    if (bio != null) payload['bio'] = bio;
    if (wilaya != null) payload['wilaya'] = wilaya;
    // avatarPath would be handled via multipart in a real impl; for now include as field
    if (avatarPath != null) payload['avatar'] = avatarPath;

    final data = await _remote.updateProfile(payload);
    return _parseUser(data);
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  Future<void> _persistTokens(Map<String, dynamic> data) async {
    final accessToken = _safeString(data, ['access_token', 'token', 'accessToken']);
    final refreshToken = _safeString(data, ['refresh_token', 'refreshToken']);
    final userId = _safeString(data, ['user', 'id']) ??
        _safeString(data, ['id']);

    if (accessToken != null) {
      await _local.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
      );
    }
    if (userId != null) {
      await _local.setUserId(userId);
    }
  }

  User _parseUser(Map<String, dynamic> data) {
    // The user object may be nested under a "user" key
    final Map<String, dynamic> userMap =
        (data['user'] is Map<String, dynamic>)
            ? data['user'] as Map<String, dynamic>
            : data;
    return User.fromJson(userMap);
  }

  String? _safeString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final parts = key.split('.');
      dynamic current = map;
      for (final part in parts) {
        if (current is Map<String, dynamic> && current.containsKey(part)) {
          current = current[part];
        } else {
          current = null;
          break;
        }
      }
      if (current is String && current.isNotEmpty) return current;
    }
    return null;
  }
}
