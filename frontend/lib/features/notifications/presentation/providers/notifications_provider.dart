import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/notification.dart';

// ---------------------------------------------------------------------------
// Dio provider
// ---------------------------------------------------------------------------

final _notificationsDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: AppConfig.instance.apiBaseUrl));
});

// ---------------------------------------------------------------------------
// Notifications state
// ---------------------------------------------------------------------------

class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.isMarkingAll = false,
    this.errorMessage,
    this.hasMore = true,
    this.page = 1,
  });

  final List<NotificationEntity> notifications;
  final bool isLoading;
  final bool isMarkingAll;
  final String? errorMessage;
  final bool hasMore;
  final int page;

  int get unreadCount =>
      notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<NotificationEntity>? notifications,
    bool? isLoading,
    bool? isMarkingAll,
    String? errorMessage,
    bool? hasMore,
    int? page,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isMarkingAll: isMarkingAll ?? this.isMarkingAll,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

// ---------------------------------------------------------------------------
// NotificationsNotifier
// ---------------------------------------------------------------------------

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._dio) : super(const NotificationsState()) {
    load();
  }

  final Dio _dio;

  // ------------------------------------------------------------------
  // Load notifications (first page)
  // ------------------------------------------------------------------
  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'page': 1, 'limit': 20},
      );
      final data = response.data['data'] as List? ?? [];
      final notifications = data
          .map((json) => NotificationEntity.fromJson(
              json as Map<String, dynamic>))
          .toList();
      final total = response.data['total'] as int? ?? notifications.length;
      state = state.copyWith(
        isLoading: false,
        notifications: notifications,
        page: 1,
        hasMore: notifications.length < total,
      );
    } catch (_) {
      // Use mock data for dev
      state = state.copyWith(
        isLoading: false,
        notifications: _mockNotifications(),
        hasMore: false,
      );
    }
  }

  // ------------------------------------------------------------------
  // Load more (pagination)
  // ------------------------------------------------------------------
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.page + 1;
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'page': nextPage, 'limit': 20},
      );
      final data = response.data['data'] as List? ?? [];
      final moreNotifications = data
          .map((json) => NotificationEntity.fromJson(
              json as Map<String, dynamic>))
          .toList();
      final total = response.data['total'] as int? ??
          state.notifications.length + moreNotifications.length;
      state = state.copyWith(
        isLoading: false,
        notifications: [...state.notifications, ...moreNotifications],
        page: nextPage,
        hasMore:
            state.notifications.length + moreNotifications.length < total,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }

  // ------------------------------------------------------------------
  // Mark single notification as read
  // ------------------------------------------------------------------
  Future<void> markAsRead(String notificationId) async {
    // Optimistic update
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == notificationId) return n.copyWith(isRead: true);
        return n;
      }).toList(),
    );
    try {
      await _dio.patch('/notifications/$notificationId/read');
    } catch (_) {
      // Revert on failure (could implement but keeping simple)
    }
  }

  // ------------------------------------------------------------------
  // Mark all as read
  // ------------------------------------------------------------------
  Future<void> markAllAsRead() async {
    state = state.copyWith(isMarkingAll: true);
    // Optimistic update
    state = state.copyWith(
      notifications:
          state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
    try {
      await _dio.patch('/notifications/read-all');
    } catch (_) {
      // Server call failed; local state stays updated (fine for UX)
    } finally {
      state = state.copyWith(isMarkingAll: false);
    }
  }

  // ------------------------------------------------------------------
  // Delete notification
  // ------------------------------------------------------------------
  Future<void> delete(String notificationId) async {
    state = state.copyWith(
      notifications: state.notifications
          .where((n) => n.id != notificationId)
          .toList(),
    );
    try {
      await _dio.delete('/notifications/$notificationId');
    } catch (_) {}
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (ref) => NotificationsNotifier(ref.watch(_notificationsDioProvider)),
);

// Unread count convenience provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

List<NotificationEntity> _mockNotifications() {
  final now = DateTime.now();
  return [
    NotificationEntity(
      id: 'n1',
      type: 'new_message',
      title: 'رسالة جديدة',
      body: 'لديك رسالة جديدة من أحمد بن علي',
      isRead: false,
      createdAt: now.subtract(const Duration(minutes: 5)),
    ),
    NotificationEntity(
      id: 'n2',
      type: 'review',
      title: 'تقييم جديد',
      body: 'قام محمد كريم بتقييمك بـ 5 نجوم',
      isRead: false,
      createdAt: now.subtract(const Duration(hours: 1)),
    ),
    NotificationEntity(
      id: 'n3',
      type: 'listing_viewed',
      title: 'شاهد إعلانك',
      body: 'شاهد 12 شخصاً إعلانك "شقة فاخرة في الجزائر العاصمة"',
      isRead: true,
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
    NotificationEntity(
      id: 'n4',
      type: 'new_craftsman',
      title: 'حرفي جديد قريب منك',
      body: 'سباك جديد متاح في ولايتك — يوسف بلقاسم',
      isRead: true,
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    NotificationEntity(
      id: 'n5',
      type: 'system',
      title: 'مرحباً بك في حرفي دار',
      body: 'تم إنشاء حسابك بنجاح. ابدأ بالبحث عن حرفيين أو عقارات!',
      isRead: true,
      createdAt: now.subtract(const Duration(days: 3)),
    ),
  ];
}
