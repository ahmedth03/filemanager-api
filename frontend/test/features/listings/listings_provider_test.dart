import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';

import 'package:harfidar/features/listings/presentation/providers/listings_provider.dart';
import 'package:harfidar/core/network/api_client.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> mockListingResponse({int count = 3}) => {
  'data': {
    'listings': List.generate(count, (i) => {
      'id': 'l$i',
      'ownerId': 'u1',
      'title': 'شقة ${i + 1} غرف',
      'description': 'وصف تجريبي',
      'type': 'APARTMENT',
      'status': 'ACTIVE',
      'price': '45000',
      'pricePeriod': 'monthly',
      'wilaya': 'W16',
      'city': 'الجزائر',
      'rooms': i + 1,
      'bathrooms': 1,
      'isAvailable': true,
      'avgRating': 0.0,
      'totalReviews': 0,
      'viewCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'images': [],
      'owner': {'id': 'u1', 'firstName': 'مالك', 'lastName': 'العقار', 'avatarUrl': null},
    }),
    'total': count,
    'page': 1,
    'limit': 20,
    'totalPages': 1,
  }
};

void main() {
  group('ListingsState', () {
    test('initial state is empty', () {
      const state = ListingsState();
      expect(state.listings, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.hasMore, isTrue);
    });

    test('copyWith creates updated copy', () {
      const state = ListingsState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(state.isLoading, isFalse);
    });
  });

  group('ListingsNotifier', () {
    late ProviderContainer container;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(mockDio)],
      );
    });

    tearDown(() => container.dispose());

    test('loads listings successfully', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/v1/listings'),
        statusCode: 200,
        data: mockListingResponse(count: 3),
      ));

      await container.read(listingsProvider.notifier).loadListings();

      final state = container.read(listingsProvider);
      expect(state.listings.length, equals(3));
      expect(state.error, isNull);
    });

    test('handles API error gracefully', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/v1/listings'),
        type: DioExceptionType.connectionError,
      ));

      await container.read(listingsProvider.notifier).loadListings();

      final state = container.read(listingsProvider);
      expect(state.error, isNotNull);
      expect(state.listings, isEmpty);
    });

    test('hasMore is false when total equals loaded count', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/v1/listings'),
        statusCode: 200,
        data: mockListingResponse(count: 2),
      ));

      await container.read(listingsProvider.notifier).loadListings();

      expect(container.read(listingsProvider).hasMore, isFalse);
    });
  });
}
