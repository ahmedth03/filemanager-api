import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';

final listingsRemoteDatasourceProvider =
    Provider<ListingsRemoteDatasource>((ref) {
  return ListingsRemoteDatasource(ref.watch(dioProvider));
});

class ListingsRemoteDatasource {
  const ListingsRemoteDatasource(this._dio);

  final Dio _dio;

  // ── Fetch list ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getListings({
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _dio.get(
        '/v1/listings',
        queryParameters: params,
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Single listing ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getListingById(String id) async {
    try {
      final response = await _dio.get('/v1/listings/$id');
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── My listings ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMyListings() async {
    try {
      final response = await _dio.get('/v1/listings/my');
      final data = _extractData(response);
      final list = (data['listings'] as List<dynamic>?) ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createListing(
      Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/v1/listings', data: body);
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> updateListing(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.put('/v1/listings/$id', data: body);
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  Future<void> deleteListing(String id) async {
    try {
      await _dio.delete('/v1/listings/$id');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Upload image ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> uploadImage({
    required String listingId,
    required String filePath,
    required bool isCover,
    required int order,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
        'isCover': isCover.toString(),
        'order': order.toString(),
      });
      final response = await _dio.post(
        '/v1/listings/$listingId/images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Delete image ────────────────────────────────────────────────────────────

  Future<void> deleteImage(String listingId, String imageId) async {
    try {
      await _dio.delete('/v1/listings/$listingId/images/$imageId');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Favorites ───────────────────────────────────────────────────────────────

  Future<void> toggleFavorite(String listingId) async {
    try {
      await _dio.post('/v1/listings/$listingId/favorite');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<String>> getFavoriteIds() async {
    try {
      final response = await _dio.get('/v1/listings/favorites');
      final data = _extractData(response);
      final ids = (data['ids'] as List<dynamic>?) ?? [];
      return ids.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Search ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> searchListings({
    required String query,
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _dio.get(
        '/v1/listings/search',
        queryParameters: {'q': query, ...?params},
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Reviews ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getReviews(String listingId) async {
    try {
      final response = await _dio.get('/v1/listings/$listingId/reviews');
      final data = _extractData(response);
      final list = (data['reviews'] as List<dynamic>?) ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> addReview({
    required String listingId,
    required double rating,
    required String comment,
  }) async {
    try {
      final response = await _dio.post(
        '/v1/listings/$listingId/reviews',
        data: {'rating': rating, 'comment': comment},
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Map<String, dynamic> _extractData(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return (body['data'] as Map<String, dynamic>?) ?? body;
    }
    return {};
  }

  Exception _mapError(DioException e) {
    final status = e.response?.statusCode;
    final message = _extractMessage(e);
    switch (status) {
      case 401:
        return UnauthorizedException(message);
      case 403:
        return UnauthorizedException(message, 403);
      case 404:
        return NotFoundException(message);
      case 422:
        return ValidationException(
          message: message,
          errors: _extractErrors(e),
        );
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return const TimeoutException();
        }
        if (e.type == DioExceptionType.connectionError) {
          return const NetworkException();
        }
        return ServerException(
          message: message,
          statusCode: status ?? 500,
        );
    }
  }

  String _extractMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message']?.toString() ?? e.message ?? 'Unknown error';
      }
    } catch (_) {}
    return e.message ?? 'Unknown error';
  }

  Map<String, List<String>> _extractErrors(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['errors'] is Map) {
        final errors = data['errors'] as Map<String, dynamic>;
        return errors.map(
          (key, value) => MapEntry(
            key,
            (value as List).map((v) => v.toString()).toList(),
          ),
        );
      }
    } catch (_) {}
    return {};
  }
}
