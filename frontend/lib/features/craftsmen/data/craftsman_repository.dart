import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/models/paginated_result.dart';
import 'craftsman_model.dart';

class CraftsmanRepository {
  final Dio _dio = DioClient.instance;

  Future<PaginatedResult<CraftsmanModel>> getCraftsmen({
    int page = 1,
    int limit = 20,
    String? wilaya,
    String? specialtyId,
    bool? isAvailable,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (wilaya != null) 'wilaya': wilaya,
        if (specialtyId != null) 'specialtyId': specialtyId,
        if (isAvailable != null) 'isAvailable': isAvailable,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response =
          await _dio.get('/craftsmen', queryParameters: queryParams);
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
            .map((e) => CraftsmanModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        meta: meta,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<SpecialtyModel>> getSpecialties() async {
    try {
      final response = await _dio.get('/craftsmen/specialties');
      final List data = response.data['data'] ?? response.data ?? [];
      return data
          .map((e) => SpecialtyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CraftsmanModel> getCraftsman(String id) async {
    try {
      final response = await _dio.get('/craftsmen/$id');
      final data = response.data['data'] ?? response.data;
      return CraftsmanModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
