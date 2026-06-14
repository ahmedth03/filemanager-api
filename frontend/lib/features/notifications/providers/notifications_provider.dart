import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../data/notification_model.dart';

Future<List<NotificationModel>> _fetchNotifications() async {
  final response = await DioClient.instance.get('/notifications?page=1&limit=50');
  final List data = (response.data['data'] ?? response.data)['data'] ?? [];
  return data.map((e) => NotificationModel.fromJson(e)).toList();
}

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  return _fetchNotifications();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final response =
      await DioClient.instance.get('/notifications/unread-count');
  final data = response.data['data'] ?? response.data;
  return (data['count'] ?? 0) as int;
});

Future<void> markNotificationRead(String id) async {
  await DioClient.instance.patch('/notifications/$id/read');
}

Future<void> markAllNotificationsRead() async {
  await DioClient.instance.patch('/notifications/read-all');
}
