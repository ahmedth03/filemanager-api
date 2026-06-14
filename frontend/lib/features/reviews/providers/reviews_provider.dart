import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/review_model.dart';

final craftsmanReviewsProvider =
    FutureProvider.autoDispose.family<List<ReviewModel>, String>((ref, craftsmanId) async {
  final response = await DioClient.instance
      .get('/reviews/craftsman/$craftsmanId?page=1&limit=20');
  final raw = response.data['data'] ?? response.data;
  final List list = raw['data'] ?? raw ?? [];
  return list.map((e) => ReviewModel.fromJson(e)).toList();
});

final listingReviewsProvider =
    FutureProvider.autoDispose.family<List<ReviewModel>, String>((ref, listingId) async {
  final response = await DioClient.instance
      .get('/reviews/listing/$listingId?page=1&limit=20');
  final raw = response.data['data'] ?? response.data;
  final List list = raw['data'] ?? raw ?? [];
  return list.map((e) => ReviewModel.fromJson(e)).toList();
});

Future<void> submitReview({
  required int rating,
  String? comment,
  String? craftsmanId,
  String? listingId,
}) async {
  await DioClient.instance.post('/reviews', data: {
    'rating': rating,
    if (comment != null && comment.isNotEmpty) 'comment': comment,
    if (craftsmanId != null) 'craftsmanId': craftsmanId,
    if (listingId != null) 'listingId': listingId,
  });
}
