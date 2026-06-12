import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../domain/entities/chat_room.dart';
import '../providers/chat_provider.dart';

// ---------------------------------------------------------------------------
// Chat List Screen
// ---------------------------------------------------------------------------

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load rooms on first render and ensure socket is connected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(chatProvider.notifier);
      notifier.connect();
      notifier.loadRooms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatRoom> _filteredRooms(List<ChatRoom> rooms) {
    if (_searchQuery.trim().isEmpty) return rooms;
    return ref.read(chatProvider.notifier).searchRooms(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final displayRooms = _filteredRooms(chatState.rooms);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _buildBody(chatState, displayRooms),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'رسائلي',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        Consumer(builder: (context, ref, _) {
          final isConnected = ref.watch(isChatConnectedProvider);
          return Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Tooltip(
              message: isConnected ? 'متصل' : 'غير متصل',
              child: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'ابحث في المحادثات...',
          hintStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildBody(ChatState chatState, List<ChatRoom> rooms) {
    if (chatState.isLoadingRooms) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (chatState.error != null && rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              chatState.error!,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.read(chatProvider.notifier).loadRooms(),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (rooms.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.chat_bubble_outline,
        title: 'لا توجد محادثات بعد',
        subtitle: _searchQuery.isNotEmpty
            ? 'لا توجد نتائج لـ "$_searchQuery"'
            : 'ابدأ محادثة مع حرفي أو مالك عقار',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(chatProvider.notifier).loadRooms(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rooms.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 76,
          color: AppColors.divider,
        ),
        itemBuilder: (context, index) {
          return _ChatRoomTile(room: rooms[index]);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat Room List Tile
// ---------------------------------------------------------------------------

class _ChatRoomTile extends ConsumerWidget {
  const _ChatRoomTile({required this.room});

  final ChatRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isUserOnlineProvider(
        room.participants.firstWhere(
          (p) => p != (ref.watch(chatProvider).rooms.isEmpty ? '' : p),
          orElse: () => '',
        )));

    final lastMsg = room.lastMessage;
    final timeStr = lastMsg != null ? _formatTime(lastMsg.createdAt) : '';

    return InkWell(
      onTap: () {
        ref.read(chatProvider.notifier).enterRoom(room.id);
        context.push('/main/chats/${room.id}', extra: room);
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────────────
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: room.otherUserAvatar != null
                      ? NetworkImage(room.otherUserAvatar!)
                      : null,
                  child: room.otherUserAvatar == null
                      ? Text(
                          _initials(room.otherUserName),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // ── Name + last message ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.otherUserName,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: room.hasUnread
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (lastMsg != null)
                    Text(
                      lastMsg.isImage
                          ? '📷 صورة'
                          : lastMsg.isFile
                              ? '📎 ملف'
                              : lastMsg.content,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: room.hasUnread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: room.hasUnread
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    const Text(
                      'لا توجد رسائل بعد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),

            // ── Time + unread badge ──────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: room.hasUnread
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                if (room.hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      room.unreadCount > 99
                          ? '99+'
                          : '${room.unreadCount}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(dt);
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return days[dt.weekday % 7];
    } else {
      return DateFormat('dd/MM/yy').format(dt);
    }
  }
}
