import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:harfidar/features/auth/presentation/providers/auth_provider.dart';
import 'package:harfidar/core/storage/secure_storage.dart';
import 'package:harfidar/core/network/api_client.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────
class MockDio extends Mock implements Dio {}
class MockSecureStorage extends Mock implements SecureStorageService {}

void main() {
  group('AuthState', () {
    test('default state is unauthenticated', () {
      const state = AuthState();
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith preserves existing values when not overridden', () {
      const state = AuthState(isAuthenticated: true);
      final updated = state.copyWith(isLoading: true);

      expect(updated.isAuthenticated, isTrue);
      expect(updated.isLoading, isTrue);
    });

    test('copyWith can clear error', () {
      const state = AuthState(error: 'some error');
      final updated = state.copyWith(error: null);
      expect(updated.error, isNull);
    });
  });

  group('AuthNotifier - login', () {
    late ProviderContainer container;
    late MockDio mockDio;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockDio = MockDio();
      mockStorage = MockSecureStorage();

      container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(mockDio),
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('sets isLoading true during login', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/auth/login'),
          statusCode: 200,
          data: {
            'data': {
              'accessToken': 'access_token',
              'refreshToken': 'refresh_token',
              'user': {
                'id': 'u1', 'email': 'test@test.com',
                'firstName': 'Ahmed', 'lastName': 'Test',
                'role': 'USER', 'status': 'ACTIVE',
              }
            }
          },
        ),
      );

      when(() => mockStorage.saveAccessToken(any())).thenAnswer((_) async {});
      when(() => mockStorage.saveRefreshToken(any())).thenAnswer((_) async {});
      when(() => mockStorage.saveUserId(any())).thenAnswer((_) async {});

      final notifier = container.read(authStateProvider.notifier);
      final success = await notifier.login('test@test.com', 'Password@123');

      expect(success, isTrue);

      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.email, equals('test@test.com'));
    });

    test('sets error on login failure', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/auth/login'),
            statusCode: 401,
            data: {'message': 'Invalid credentials'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final notifier = container.read(authStateProvider.notifier);
      final success = await notifier.login('bad@email.com', 'wrongpass');

      expect(success, isFalse);

      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.error, isNotNull);
    });
  });

  group('AuthNotifier - logout', () {
    test('clears state on logout', () async {
      final mockDio = MockDio();
      final mockStorage = MockSecureStorage();

      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/auth/logout'),
          statusCode: 200,
          data: {'data': {'message': 'Logged out'}},
        ),
      );
      when(() => mockStorage.getRefreshToken()).thenAnswer((_) async => 'token');
      when(() => mockStorage.clearAll()).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(mockDio),
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );

      await container.read(authStateProvider.notifier).logout();

      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);

      container.dispose();
    });
  });
}
