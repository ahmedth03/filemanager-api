import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/models/paginated_result.dart';
import 'property_model.dart';

class PropertyRepository {
  final Dio _dio = DioClient.instance;

  Future<PaginatedResult<PropertyModel>> getListings({
    int page = 1,
    int limit = 20,
    String? wilaya,
    String? type,
    double? minPrice,
    double? maxPrice,
    int? rooms,
    bool? isFurnished,
    String? search,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (wilaya != null) 'wilaya': wilaya,
        if (type != null) 'type': type,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (rooms != null) 'rooms': rooms,
        if (isFurnished != null) 'isFurnished': isFurnished,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sortBy != null) 'sortBy': sortBy,
      };

      final response =
          await _dio.get('/listings', queryParameters: queryParams);
      final body = response.data['data'] ?? response.data;

      List<dynamic> items;
      PaginatedMeta meta;

      if (body is Map && body.containsKey('data')) {
        items = body['data'] as List<dynamic>? ?? [];
        meta = PaginatedMeta.fromJson(
            body['meta'] as Map<String, dynamic>? ?? {});
      } else if (body is List) {
        items = body;
        meta = PaginatedMeta.empty();
      } else {
        items = [];
        meta = PaginatedMeta.empty();
      }

      return PaginatedResult(
        data: items
            .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        meta: meta,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PropertyModel> getListing(String id) async {
    try {
      final response = await _dio.get('/listings/$id');
      final data = response.data['data'] ?? response.data;
      return PropertyModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<PropertyModel>> getMyListings() async {
    try {
      final response = await _dio.get('/listings/my');
      final List data = response.data['data'] ?? response.data ?? [];
      return data
          .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PropertyModel> createListing(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/listings', data: data);
      final resData = response.data['data'] ?? response.data;
      return PropertyModel.fromJson(resData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteListing(String id) async {
    try {
      await _dio.delete('/listings/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
