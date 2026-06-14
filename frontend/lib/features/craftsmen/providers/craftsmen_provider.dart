import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../data/craftsman_model.dart';

final craftsmenProvider = FutureProvider<List<CraftsmanModel>>((ref) async {
  try {
    final response = await DioClient.instance.get('/craftsmen');
    final List data = response.data['data'] ?? response.data ?? [];
    return data.map((e) => CraftsmanModel.fromJson(e)).toList();
  } on DioException catch (e) {
    throw Exception('فشل تحميل الحرفيين');
  }
});
