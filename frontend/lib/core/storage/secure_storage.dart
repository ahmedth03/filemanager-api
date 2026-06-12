import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Riverpod provider that exposes a [SecureStorage] singleton.
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage._();
});

/// Thin wrapper around [FlutterSecureStorage] for token management.
///
/// All keys are grouped under [_Keys] to avoid typos.
class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _Keys _k = _Keys._();

  // ── Access token ──────────────────────────────────────────────────────────
  Future<String?> getAccessToken() => _storage.read(key: _k.accessToken);

  Future<void> setAccessToken(String token) =>
      _storage.write(key: _k.accessToken, value: token);

  // ── Refresh token ─────────────────────────────────────────────────────────
  Future<String?> getRefreshToken() => _storage.read(key: _k.refreshToken);

  Future<void> setRefreshToken(String token) =>
      _storage.write(key: _k.refreshToken, value: token);

  // ── User ID ───────────────────────────────────────────────────────────────
  Future<String?> getUserId() => _storage.read(key: _k.userId);

  Future<void> setUserId(String id) =>
      _storage.write(key: _k.userId, value: id);

  // ── Device token (FCM) ────────────────────────────────────────────────────
  Future<String?> getDeviceToken() => _storage.read(key: _k.deviceToken);

  Future<void> setDeviceToken(String token) =>
      _storage.write(key: _k.deviceToken, value: token);

  // ── Convenience helpers ───────────────────────────────────────────────────

  /// Persists both access and refresh tokens in a single call.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      setAccessToken(accessToken),
      setRefreshToken(refreshToken),
    ]);
  }

  /// Returns [true] if an access token is stored (does not validate expiry).
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clears all stored authentication data (called on logout).
  Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _k.accessToken),
      _storage.delete(key: _k.refreshToken),
      _storage.delete(key: _k.userId),
    ]);
  }

  /// Erases every value in the secure storage. Use with caution.
  Future<void> clearAll() => _storage.deleteAll();
}

// ---------------------------------------------------------------------------
// Private key definitions
// ---------------------------------------------------------------------------

class _Keys {
  const _Keys._();

  final String accessToken = 'hd_access_token';
  final String refreshToken = 'hd_refresh_token';
  final String userId = 'hd_user_id';
  final String deviceToken = 'hd_device_token';
}
