// Smoke test — verifies the app bootstraps without crashing.
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:harfidar/core/storage/preferences_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('PreferencesStorage defaults', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = PreferencesStorage(prefs);

    expect(storage.isOnboardingDone, isFalse);
    expect(storage.language, equals('ar'));
    expect(storage.themeMode, equals('system'));
    expect(storage.notificationsEnabled, isTrue);
  });

  test('PreferencesStorage setOnboardingDone persists', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = PreferencesStorage(prefs);

    await storage.setOnboardingDone();
    expect(storage.isOnboardingDone, isTrue);
  });

  test('PreferencesStorage setLanguage persists', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = PreferencesStorage(prefs);

    await storage.setLanguage('fr');
    expect(storage.language, equals('fr'));
  });
}
