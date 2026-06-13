import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_item.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final hasUnread = notificationsState.unreadCount > 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Row(
            children: [
              const Text(
                'الإشعارات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              if (notificationsState.unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${notificationsState.unreadCount}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (hasUnread)
              TextButton(
                onPressed: notificationsState.isMarkingAll
                    ? null
                    : () => notifier.markAllAsRead(),
                child: notificationsState.isMarkingAll
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text(
                        'قراءة الكل',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
              ),
          ],
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => notifier.load(),
          child: notificationsState.isLoading &&
                  notificationsState.notifications.isEmpty
              ? _buildLoading()
              : notificationsState.notifications.isEmpty
                  ? _buildEmpty()
                  : _buildList(context, ref, notificationsState, notifier),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: AppColors.divider,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (_, __) => const _ShimmerNotification(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ستظهر هنا إشعاراتك ورسائلك الجديدة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    NotificationsState state,
    NotificationsNotifier notifier,
  ) {
    // Group notifications by date sections
    final today = <int>[];
    final earlier = <int>[];
    final now = DateTime.now();

    for (int i = 0; i < state.notifications.length; i++) {
      final diff =
          now.difference(state.notifications[i].createdAt).inDays;
      if (diff < 1) {
        today.add(i);
      } else {
        earlier.add(i);
      }
    }

    return ListView.builder(
      itemCount: _calculateItemCount(today, earlier, state),
      itemBuilder: (context, index) =>
          _buildListItem(context, index, today, earlier, state, notifier),
    );
  }

  int _calculateItemCount(
    List<int> today,
    List<int> earlier,
    NotificationsState state,
  ) {
    int count = 0;
    if (today.isNotEmpty) count += 1 + today.length; // header + items
    if (earlier.isNotEmpty) count += 1 + earlier.length;
    if (state.hasMore) count += 1; // load more button
    return count;
  }

  Widget _buildListItem(
    BuildContext context,
    int index,
    List<int> today,
    List<int> earlier,
    NotificationsState state,
    NotificationsNotifier notifier,
  ) {
    int pos = 0;

    // Today section header
    if (today.isNotEmpty) {
      if (index == pos) return _SectionHeader(title: 'اليوم');
      pos++;

      // Today items
      if (index < pos + today.length) {
        final i = today[index - pos];
        final n = state.notifications[i];
        return Column(
          children: [
            NotificationItem(
              notification: n,
              onTap: () {
                if (!n.isRead) notifier.markAsRead(n.id);
              },
              onDismiss: () => notifier.delete(n.id),
            ),
            if (index < pos + today.length - 1 || earlier.isNotEmpty)
              const Divider(
                  height: 1, color: AppColors.divider, indent: 72),
          ],
        );
      }
      pos += today.length;
    }

    // Earlier section header
    if (earlier.isNotEmpty) {
      if (index == pos) return _SectionHeader(title: 'سابقاً');
      pos++;

      // Earlier items
      if (index < pos + earlier.length) {
        final i = earlier[index - pos];
        final n = state.notifications[i];
        return Column(
          children: [
            NotificationItem(
              notification: n,
              onTap: () {
                if (!n.isRead) notifier.markAsRead(n.id);
              },
              onDismiss: () => notifier.delete(n.id),
            ),
            if (index < pos + earlier.length - 1)
              const Divider(
                  height: 1, color: AppColors.divider, indent: 72),
          ],
        );
      }
    }

    // Load more
    return Padding(
      padding: const EdgeInsets.all(16),
      child: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TextButton(
              onPressed: () => notifier.loadMore(),
              child: const Text(
                'تحميل المزيد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.background,
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer placeholder
// ---------------------------------------------------------------------------

class _ShimmerNotification extends StatelessWidget {
  const _ShimmerNotification();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
