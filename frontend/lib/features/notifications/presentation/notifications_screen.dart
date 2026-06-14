import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/notifications_provider.dart';
import '../data/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإشعارات', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: const Color(0xFF1B4F72),
          foregroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: () async {
                await markAllNotificationsRead();
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadCountProvider);
              },
              child: const Text('قراءة الكل',
                  style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            ),
          ],
        ),
        body: notifAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Text('تعذر تحميل الإشعارات',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600]))),
          data: (notifications) => notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('لا توجد إشعارات', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(notificationsProvider),
                  child: ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) =>
                        _NotificationTile(notification: notifications[i], ref: ref),
                  ),
                ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final WidgetRef ref;

  const _NotificationTile({required this.notification, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: notification.isRead ? null : const Color(0xFF1B4F72).withOpacity(0.05),
      leading: CircleAvatar(
        backgroundColor: notification.isRead
            ? Colors.grey[200]
            : const Color(0xFF1B4F72).withOpacity(0.15),
        child: Icon(
          _iconForType(notification.type),
          color: notification.isRead ? Colors.grey : const Color(0xFF1B4F72),
          size: 20,
        ),
      ),
      title: Text(notification.title,
          style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold)),
      subtitle: Text(notification.body,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
      trailing: !notification.isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Color(0xFF1B4F72), shape: BoxShape.circle))
          : null,
      onTap: notification.isRead
          ? null
          : () async {
              await markNotificationRead(notification.id);
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'MESSAGE':
        return Icons.chat_bubble_outline;
      case 'REVIEW':
        return Icons.star_outline;
      case 'LISTING_APPROVED':
        return Icons.check_circle_outline;
      case 'CRAFTSMAN_VERIFIED':
        return Icons.verified_outlined;
      default:
        return Icons.notifications_none;
    }
  }
}
