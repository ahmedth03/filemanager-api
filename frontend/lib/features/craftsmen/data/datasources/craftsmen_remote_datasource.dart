import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/craftsman.dart';
import '../../domain/repositories/craftsmen_repository.dart';

final craftsmenRemoteDatasourceProvider = Provider<CraftsmenRemoteDatasource>(
  (ref) => CraftsmenRemoteDatasource(ref.watch(dioProvider)),
);

class CraftsmenRemoteDatasource {
  const CraftsmenRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<Craftsman>> getCraftsmen(CraftsmenFilters filters) async {
    try {
      final response = await _dio.get(
        '/craftsmen',
        queryParameters: filters.toQueryParams(),
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data
          .map((json) => Craftsman.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
    return [];
  }

  Future<List<Craftsman>> searchCraftsmen(
    String query, {
    CraftsmenFilters? filters,
  }) async {
    try {
      final params = filters?.toQueryParams() ?? {};
      params['q'] = query;
      final response = await _dio.get(
        '/craftsmen/search',
        queryParameters: params,
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data
          .map((json) => Craftsman.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
    return [];
  }

  Future<Craftsman> getCraftsmanById(String id) async {
    try {
      final response = await _dio.get('/craftsmen/$id');
      return Craftsman.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<Craftsman> createCraftsmanProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/craftsmen', data: data);
      return Craftsman.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<Craftsman> updateCraftsmanProfile(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/craftsmen/$id', data: data);
      return Craftsman.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<void> deleteCraftsmanProfile(String id) async {
    try {
      await _dio.delete('/craftsmen/$id');
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<int> getCraftsmenCount(CraftsmenFilters filters) async {
    try {
      final params = filters.toQueryParams();
      params['countOnly'] = true;
      final response = await _dio.get('/craftsmen/count', queryParameters: params);
      return (response.data['count'] as int?) ?? 0;
    } on DioException catch (_) {
      return 0;
    }
  }

  Never _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e);

    switch (statusCode) {
      case 401:
        throw UnauthorizedException(message);
      case 403:
        throw UnauthorizedException(message, 403);
      case 404:
        throw NotFoundException(message);
      case 422:
        throw ValidationException(
          message: message,
          errors: _extractErrors(e),
        );
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw const TimeoutException();
        }
        if (e.type == DioExceptionType.connectionError) {
          throw const NetworkException();
        }
        throw ServerException(
          message: message,
          statusCode: statusCode ?? 500,
        );
    }
  }

  String _extractMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? e.message ?? 'Unknown error';
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
            (value as List).map((e) => e.toString()).toList(),
          ),
        );
      }
    } catch (_) {}
    return {};
  }
}
