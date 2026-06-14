import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chat_provider.dart';
import '../data/chat_model.dart';
import '../../auth/providers/auth_provider.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(chatRoomsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المحادثات', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: const Color(0xFF1B4F72),
          foregroundColor: Colors.white,
        ),
        body: roomsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('تعذر تحميل المحادثات',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(chatRoomsProvider),
                  child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          ),
          data: (rooms) => rooms.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('لا توجد محادثات بعد',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('ابدأ محادثة من صفحة الحرفيين أو العقارات',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey),
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(chatRoomsProvider),
                  child: ListView.separated(
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final room = rooms[i];
                      final other = room.members
                          .where((m) => m.id != currentUser?.id)
                          .firstOrNull;
                      final name = other?.fullName ?? 'محادثة';
                      final initials = name.isNotEmpty ? name[0] : '?';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1B4F72),
                          child: Text(initials,
                              style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                        ),
                        title: Text(name,
                            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
                        subtitle: room.lastMessage != null
                            ? Text(room.lastMessage!,
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)
                            : const Text('لا توجد رسائل بعد',
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey)),
                        trailing: room.lastMessageAt != null
                            ? Text(_formatTime(room.lastMessageAt!),
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'))
                            : null,
                        onTap: () => context.push('/chat/${room.id}'),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}
