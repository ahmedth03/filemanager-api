import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Riverpod provider for [PreferencesStorage].
///
/// Because [SharedPreferences.getInstance] is async, this is an async provider.
/// Use [preferencesStorageProvider] in consumers that need async init, or
/// directly inject an already-resolved [PreferencesStorage] when available.
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final preferencesStorageProvider = Provider<PreferencesStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).when(
        data: (p) => p,
        loading: () => null,
        error: (_, __) => null,
      );
  return PreferencesStorage(prefs);
});

/// Wrapper around [SharedPreferences] for non-sensitive app settings.
///
/// Sensitive data (tokens) lives in [SecureStorage] instead.
class PreferencesStorage {
  PreferencesStorage(this._prefs);

  final SharedPreferences? _prefs;

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const String _keyOnboardingDone = 'hd_onboarding_done';
  static const String _keyAppLanguage = 'hd_app_language';
  static const String _keyThemeMode = 'hd_theme_mode';
  static const String _keyNotificationsEnabled = 'hd_notifications_enabled';
  static const String _keyLastSearchQuery = 'hd_last_search_query';
  static const String _keySelectedWilaya = 'hd_selected_wilaya';
  static const String _keyRememberMe = 'hd_remember_me';
  static const String _keyCachedUserJson = 'hd_cached_user_json';
  static const String _keyAppVersion = 'hd_app_version';

  // ── Onboarding ────────────────────────────────────────────────────────────
  bool get isOnboardingDone =>
      _prefs?.getBool(_keyOnboardingDone) ?? false;

  Future<void> setOnboardingDone(bool value) async =>
      _prefs?.setBool(_keyOnboardingDone, value);

  // ── Language ──────────────────────────────────────────────────────────────
  /// Returns language code, e.g. 'ar', 'fr', 'en'. Defaults to 'ar'.
  String get appLanguage => _prefs?.getString(_keyAppLanguage) ?? 'ar';

  Future<void> setAppLanguage(String languageCode) async =>
      _prefs?.setString(_keyAppLanguage, languageCode);

  // ── Theme ─────────────────────────────────────────────────────────────────
  /// Returns stored theme mode string: 'light', 'dark', or 'system'.
  String get themeMode => _prefs?.getString(_keyThemeMode) ?? 'light';

  Future<void> setThemeMode(String mode) async =>
      _prefs?.setString(_keyThemeMode, mode);

  // ── Notifications ─────────────────────────────────────────────────────────
  bool get notificationsEnabled =>
      _prefs?.getBool(_keyNotificationsEnabled) ?? true;

  Future<void> setNotificationsEnabled(bool value) async =>
      _prefs?.setBool(_keyNotificationsEnabled, value);

  // ── Last search query ─────────────────────────────────────────────────────
  String get lastSearchQuery =>
      _prefs?.getString(_keyLastSearchQuery) ?? '';

  Future<void> setLastSearchQuery(String query) async =>
      _prefs?.setString(_keyLastSearchQuery, query);

  // ── Selected wilaya ───────────────────────────────────────────────────────
  /// Selected wilaya code (1-58), or null if not set.
  int? get selectedWilaya {
    final v = _prefs?.getInt(_keySelectedWilaya);
    return v == 0 ? null : v;
  }

  Future<void> setSelectedWilaya(int? wilayaCode) async =>
      _prefs?.setInt(_keySelectedWilaya, wilayaCode ?? 0);

  // ── Remember me ───────────────────────────────────────────────────────────
  bool get rememberMe => _prefs?.getBool(_keyRememberMe) ?? false;

  Future<void> setRememberMe(bool value) async =>
      _prefs?.setBool(_keyRememberMe, value);

  // ── Cached user profile JSON string ──────────────────────────────────────
  String? get cachedUserJson => _prefs?.getString(_keyCachedUserJson);

  Future<void> setCachedUserJson(String? json) async {
    if (json == null) {
      await _prefs?.remove(_keyCachedUserJson);
    } else {
      await _prefs?.setString(_keyCachedUserJson, json);
    }
  }

  // ── App version (for migration checks) ───────────────────────────────────
  String? get appVersion => _prefs?.getString(_keyAppVersion);

  Future<void> setAppVersion(String version) async =>
      _prefs?.setString(_keyAppVersion, version);

  // ── Clear ─────────────────────────────────────────────────────────────────
  /// Clears all preferences EXCEPT [_keyAppLanguage] and [_keyThemeMode]
  /// so the user does not lose their UI preferences on logout.
  Future<void> clearUserData() async {
    final language = appLanguage;
    final theme = themeMode;
    await _prefs?.clear();
    await setAppLanguage(language);
    await setThemeMode(theme);
  }

  /// Clears every preference unconditionally.
  Future<void> clearAll() async => _prefs?.clear();
}
