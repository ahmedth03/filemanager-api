import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';

import 'package:harfidar/features/craftsmen/presentation/providers/craftsmen_provider.dart';
import 'package:harfidar/core/network/api_client.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> mockCraftsmanResponse({int count = 3}) => {
  'data': {
    'craftsmen': List.generate(count, (i) => {
      'id': 'c$i',
      'userId': 'u$i',
      'bio': 'Bio $i',
      'yearsExperience': i + 1,
      'wilaya': 'W16',
      'city': 'الجزائر',
      'status': 'VERIFIED',
      'isAvailable': true,
      'avgRating': 4.5,
      'totalReviews': 10,
      'user': {'id': 'u$i', 'firstName': 'حرفي', 'lastName': '$i', 'avatarUrl': null},
      'specialty': {'id': 's1', 'nameAr': 'سباك', 'nameFr': 'Plombier', 'icon': null},
      'portfolio': [],
    }),
    'total': count,
    'page': 1,
    'limit': 20,
    'totalPages': 1,
  }
};

void main() {
  group('CraftsmenState', () {
    test('default state has empty craftsmen list', () {
      const state = CraftsmenState();
      expect(state.craftsmen, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.hasMore, isTrue);
      expect(state.page, equals(1));
    });

    test('copyWith creates new state with updated values', () {
      const state = CraftsmenState();
      final updated = state.copyWith(isLoading: true, page: 2);

      expect(updated.isLoading, isTrue);
      expect(updated.page, equals(2));
      expect(state.isLoading, isFalse); // original unchanged
    });
  });

  group('CraftsmenNotifier', () {
    late ProviderContainer container;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(mockDio)],
      );
    });

    tearDown(() => container.dispose());

    test('loads craftsmen on initialization', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/v1/craftsmen'),
        statusCode: 200,
        data: mockCraftsmanResponse(count: 3),
      ));

      // Read provider to trigger initialization
      container.read(craftsmenProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(craftsmenProvider);
      expect(state.isLoading, isFalse);
      expect(state.craftsmen.length, equals(3));
      expect(state.total, equals(3));
    });

    test('sets isLoading to true during fetch', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Response(
          requestOptions: RequestOptions(path: '/v1/craftsmen'),
          statusCode: 200,
          data: mockCraftsmanResponse(),
        );
      });

      container.read(craftsmenProvider.notifier).loadCraftsmen();
      final loadingState = container.read(craftsmenProvider);
      expect(loadingState.isLoading, isTrue);
    });

    test('sets error on API failure', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/v1/craftsmen'),
        type: DioExceptionType.connectionError,
      ));

      await container.read(craftsmenProvider.notifier).loadCraftsmen();

      final state = container.read(craftsmenProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('hasMore is false when all items loaded', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/v1/craftsmen'),
        statusCode: 200,
        data: mockCraftsmanResponse(count: 3), // 3 items, total = 3
      ));

      await container.read(craftsmenProvider.notifier).loadCraftsmen();

      final state = container.read(craftsmenProvider);
      expect(state.hasMore, isFalse);
    });

    test('applyFilters resets page to 1', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/v1/craftsmen'),
        statusCode: 200,
        data: mockCraftsmanResponse(),
      ));

      await container.read(craftsmenProvider.notifier).applyFilters({'wilaya': 'W16'});

      final state = container.read(craftsmenProvider);
      expect(state.page, equals(1));
    });
  });
}
