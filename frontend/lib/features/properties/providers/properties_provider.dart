import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../data/property_model.dart';

final propertiesProvider = FutureProvider<List<PropertyModel>>((ref) async {
  try {
    final response = await DioClient.instance.get('/properties');
    final List data = response.data['data'] ?? response.data ?? [];
    return data.map((e) => PropertyModel.fromJson(e)).toList();
  } on DioException catch (e) {
    throw Exception('فشل تحميل العقارات');
  }
});
