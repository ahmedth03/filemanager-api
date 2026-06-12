import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';

// ---------------------------------------------------------------------------
// ChatRoomScreen
// ---------------------------------------------------------------------------

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.roomId,
    this.room,
  });

  final String roomId;
  final ChatRoom? room;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _shouldAutoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(chatProvider.notifier).enterRoom(widget.roomId);
      _scrollToBottom(animated: false);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    ref.read(chatProvider.notifier).leaveRoom();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    // If user scrolled up, pause auto-scroll
    final atBottom = pos.pixels >= pos.maxScrollExtent - 80;
    if (_shouldAutoScroll != atBottom) {
      setState(() => _shouldAutoScroll = atBottom);
    }

    // Load more messages when reaching the top
    if (pos.pixels <= 100) {
      ref.read(chatProvider.notifier).loadMoreMessages();
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isTyping = chatState.isTypingInCurrentRoom;

    // Find room info from state or widget param
    final roomFromState = chatState.rooms.cast<ChatRoom?>().firstWhere(
          (r) => r?.id == widget.roomId,
          orElse: () => null,
        );
    final room = roomFromState ?? widget.room;

    // Auto-scroll when new messages arrive
    ref.listen<ChatState>(chatProvider, (prev, next) {
      final prevCount = prev?.messages.length ?? 0;
      final nextCount = next.messages.length;
      if (nextCount > prevCount && _shouldAutoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEBF3FB),
        appBar: _buildAppBar(room, chatState),
        body: Column(
          children: [
            // ── Messages list ────────────────────────────────────────────
            Expanded(
              child: _buildMessageList(chatState),
            ),

            // ── Typing indicator ─────────────────────────────────────────
            if (isTyping)
              const Align(
                alignment: Alignment.centerRight,
                child: TypingBubble(),
              ),

            // ── Input bar ────────────────────────────────────────────────
            ChatInput(roomId: widget.roomId),
          ],
        ),

        // Scroll-to-bottom FAB
        floatingActionButton: _shouldAutoScroll
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: FloatingActionButton.small(
                  onPressed: () => _scrollToBottom(),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.white),
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatRoom? room, ChatState chatState) {
    // Determine if other user is online
    final otherUserId = room?.participants
        .cast<String?>()
        .firstWhere(
          (p) => p != null,
          orElse: () => null,
        );
    final isOnline = otherUserId != null &&
        chatState.onlineUsers.contains(otherUserId);

    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: room?.otherUserAvatar != null
                    ? NetworkImage(room!.otherUserAvatar!)
                    : null,
                child: room?.otherUserAvatar == null
                    ? Text(
                        _initials(room?.otherUserName ?? '?'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  room?.otherUserName ?? 'محادثة',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isOnline ? 'متصل الآن' : 'غير متصل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: isOnline
                        ? Colors.greenAccent[200]
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showRoomOptions(context),
        ),
      ],
    );
  }

  Widget _buildMessageList(ChatState chatState) {
    if (chatState.isLoadingMessages && chatState.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (chatState.error != null && chatState.messages.isEmpty) {
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
              onPressed: () =>
                  ref.read(chatProvider.notifier).enterRoom(widget.roomId),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (chatState.messages.isEmpty) {
      return const Center(
        child: Text(
          'ابدأ المحادثة الآن!',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            color: AppColors.textHint,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Group messages by date
    final grouped = _groupByDate(chatState.messages);
    final currentUserId = _currentUserId(chatState);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: grouped.length +
          (chatState.isLoadingMessages || chatState.hasMoreMessages ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at top
        if (index == 0 &&
            (chatState.isLoadingMessages || chatState.hasMoreMessages)) {
          return chatState.isLoadingMessages
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink();
        }

        final dataIndex =
            chatState.isLoadingMessages || chatState.hasMoreMessages
                ? index - 1
                : index;

        final item = grouped[dataIndex];

        if (item is String) {
          // Date separator
          return _DateSeparator(label: item);
        }

        final message = item as Message;
        final isSent = message.senderId == currentUserId;

        return MessageBubble(
          message: message,
          isSent: isSent,
          showAvatar: !isSent,
        );
      },
    );
  }

  // Groups messages into [String, Message, Message, String, ...] where
  // String is a date header.
  List<dynamic> _groupByDate(List<Message> messages) {
    final result = <dynamic>[];
    String? lastDate;

    for (final msg in messages) {
      final dateLabel = _dateLabel(msg.createdAt);
      if (dateLabel != lastDate) {
        result.add(dateLabel);
        lastDate = dateLabel;
      }
      result.add(msg);
    }

    return result;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    return DateFormat('EEEE، d MMMM y', 'ar').format(dt);
  }

  String? _currentUserId(ChatState state) {
    // Try to find own ID by cross-referencing messages and rooms
    final room = state.rooms.cast<ChatRoom?>().firstWhere(
          (r) => r?.id == widget.roomId,
          orElse: () => null,
        );
    if (room == null) return null;

    // Find the participant that sent the most messages (heuristic)
    if (state.messages.isEmpty) return null;
    final senderCounts = <String, int>{};
    for (final m in state.messages) {
      senderCounts[m.senderId] = (senderCounts[m.senderId] ?? 0) + 1;
    }
    // Look for a participant id that is not the otherUser
    for (final p in room.participants) {
      if (senderCounts.containsKey(p)) return p;
    }
    return null;
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  void _showRoomOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.block, color: AppColors.error),
                  title: const Text(
                    'حظر المستخدم',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                  title: const Text(
                    'حذف المحادثة',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Date separator widget
// ---------------------------------------------------------------------------

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}
