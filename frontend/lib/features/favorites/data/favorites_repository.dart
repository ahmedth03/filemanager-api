import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class FavoritesRepository {
  final Dio _dio = DioClient.instance;

  Future<bool> toggleFavorite({String? craftsmanId, String? listingId}) async {
    final body = craftsmanId != null
        ? {'craftsmanId': craftsmanId}
        : {'listingId': listingId};
    final response = await _dio.post('/favorites/toggle', data: body);
    final data = response.data['data'] ?? response.data;
    return data['favorited'] as bool;
  }

  Future<bool> toggleCraftsmanFavorite(String craftsmanId) async {
    final response = await _dio.post('/favorites/toggle', data: {'craftsmanId': craftsmanId});
    final data = response.data['data'] ?? response.data;
    return data['favorited'] as bool;
  }

  Future<bool> toggleListingFavorite(String listingId) async {
    final response = await _dio.post('/favorites/toggle', data: {'listingId': listingId});
    final data = response.data['data'] ?? response.data;
    return data['favorited'] as bool;
  }

  Future<bool> isCraftsmanFavorited(String craftsmanId) async {
    final response = await _dio.post('/favorites/check', data: {'craftsmanId': craftsmanId});
    final data = response.data['data'] ?? response.data;
    return data['isFavorited'] as bool;
  }

  Future<bool> isListingFavorited(String listingId) async {
    final response = await _dio.post('/favorites/check', data: {'listingId': listingId});
    final data = response.data['data'] ?? response.data;
    return data['isFavorited'] as bool;
  }

  Future<List<dynamic>> getFavorites() async {
    final response = await _dio.get('/favorites');
    return (response.data['data'] ?? response.data) as List;
  }
}
