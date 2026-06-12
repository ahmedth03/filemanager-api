import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/app_config.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

// ---------------------------------------------------------------------------
// Chat state
// ---------------------------------------------------------------------------

class ChatState {
  const ChatState({
    this.rooms = const [],
    this.messages = const [],
    this.currentRoomId,
    this.isConnected = false,
    this.isLoadingRooms = false,
    this.isLoadingMessages = false,
    this.isSending = false,
    this.typingUsers = const {},
    this.onlineUsers = const {},
    this.hasMoreMessages = true,
    this.currentPage = 1,
    this.error,
  });

  final List<ChatRoom> rooms;
  final List<Message> messages;
  final String? currentRoomId;
  final bool isConnected;
  final bool isLoadingRooms;
  final bool isLoadingMessages;
  final bool isSending;

  /// Map of roomId -> Set of userIds currently typing
  final Map<String, Set<String>> typingUsers;

  /// Set of userIds that are currently online
  final Set<String> onlineUsers;

  final bool hasMoreMessages;
  final int currentPage;
  final String? error;

  bool get isTypingInCurrentRoom {
    if (currentRoomId == null) return false;
    final users = typingUsers[currentRoomId] ?? {};
    return users.isNotEmpty;
  }

  ChatState copyWith({
    List<ChatRoom>? rooms,
    List<Message>? messages,
    String? currentRoomId,
    bool? isConnected,
    bool? isLoadingRooms,
    bool? isLoadingMessages,
    bool? isSending,
    Map<String, Set<String>>? typingUsers,
    Set<String>? onlineUsers,
    bool? hasMoreMessages,
    int? currentPage,
    String? error,
    bool clearError = false,
    bool clearCurrentRoom = false,
  }) {
    return ChatState(
      rooms: rooms ?? this.rooms,
      messages: messages ?? this.messages,
      currentRoomId:
          clearCurrentRoom ? null : currentRoomId ?? this.currentRoomId,
      isConnected: isConnected ?? this.isConnected,
      isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isSending: isSending ?? this.isSending,
      typingUsers: typingUsers ?? this.typingUsers,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    repository: ref.watch(chatRepositoryProvider),
    secureStorage: ref.watch(secureStorageProvider),
    ref: ref,
  );
});

// Convenience selectors
final chatRoomsProvider = Provider<List<ChatRoom>>((ref) {
  return ref.watch(chatProvider).rooms;
});

final currentRoomMessagesProvider = Provider<List<Message>>((ref) {
  return ref.watch(chatProvider).messages;
});

final isChatConnectedProvider = Provider<bool>((ref) {
  return ref.watch(chatProvider).isConnected;
});

final typingInRoomProvider = Provider.family<bool, String>((ref, roomId) {
  final typing = ref.watch(chatProvider).typingUsers[roomId] ?? {};
  return typing.isNotEmpty;
});

final isUserOnlineProvider = Provider.family<bool, String>((ref, userId) {
  return ref.watch(chatProvider).onlineUsers.contains(userId);
});

final unreadCountProvider = Provider<int>((ref) {
  return ref
      .watch(chatProvider)
      .rooms
      .fold(0, (sum, room) => sum + room.unreadCount);
});

// ---------------------------------------------------------------------------
// ChatNotifier
// ---------------------------------------------------------------------------

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier({
    required ChatRepository repository,
    required SecureStorage secureStorage,
    required Ref ref,
  })  : _repository = repository,
        _secureStorage = secureStorage,
        _ref = ref,
        super(const ChatState());

  final ChatRepository _repository;
  final SecureStorage _secureStorage;
  final Ref _ref;

  io.Socket? _socket;
  Timer? _typingTimer;

  // ──────────────────────────────────────────────────────────────────────────
  // Socket connection lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) return;

    final socketUrl = AppConfig.instance.socketUrl;

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setNamespace('/chat')
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        debugPrint('[Chat] Socket connected');
        state = state.copyWith(isConnected: true, clearError: true);
        _rejoinCurrentRoom();
      })
      ..onDisconnect((_) {
        debugPrint('[Chat] Socket disconnected');
        state = state.copyWith(isConnected: false);
      })
      ..onConnectError((data) {
        debugPrint('[Chat] Connection error: $data');
        state = state.copyWith(error: 'فشل الاتصال بالخادم');
      })
      ..on('message:new', _onMessageNew)
      ..on('user:typing', _onUserTyping)
      ..on('user:stop-typing', _onUserStopTyping)
      ..on('user:online', _onUserOnline)
      ..on('user:offline', _onUserOffline)
      ..on('message:read', _onMessageRead);

    _socket!.connect();
  }

  void disconnect() {
    _typingTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    state = state.copyWith(isConnected: false, clearCurrentRoom: true);
  }

  void _rejoinCurrentRoom() {
    final roomId = state.currentRoomId;
    if (roomId != null) {
      _socket?.emit('join:room', {'roomId': roomId});
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Socket event handlers
  // ──────────────────────────────────────────────────────────────────────────

  void _onMessageNew(dynamic data) {
    try {
      final message = Message.fromJson(Map<String, dynamic>.from(data as Map));

      // Update messages list if we're in this room
      if (message.chatRoomId == state.currentRoomId) {
        final updated = [...state.messages, message];
        state = state.copyWith(messages: updated);
      }

      // Update last message in rooms list
      final updatedRooms = state.rooms.map((room) {
        if (room.id == message.chatRoomId) {
          final isCurrentRoom = message.chatRoomId == state.currentRoomId;
          return room.copyWith(
            lastMessage: message,
            unreadCount: isCurrentRoom ? 0 : room.unreadCount + 1,
          );
        }
        return room;
      }).toList();

      // Sort rooms: most recent first
      updatedRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = state.copyWith(rooms: updatedRooms);

      // Auto mark as read if we're in the room
      if (message.chatRoomId == state.currentRoomId) {
        markAsRead(message.chatRoomId);
      }
    } catch (e) {
      debugPrint('[Chat] Error parsing new message: $e');
    }
  }

  void _onUserTyping(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final roomId = map['roomId'] as String;
      final userId = map['userId'] as String;

      final updated = Map<String, Set<String>>.from(state.typingUsers);
      updated[roomId] = {...(updated[roomId] ?? {}), userId};
      state = state.copyWith(typingUsers: updated);
    } catch (e) {
      debugPrint('[Chat] Error handling typing event: $e');
    }
  }

  void _onUserStopTyping(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final roomId = map['roomId'] as String;
      final userId = map['userId'] as String;

      final updated = Map<String, Set<String>>.from(state.typingUsers);
      final roomTypers = Set<String>.from(updated[roomId] ?? {});
      roomTypers.remove(userId);
      if (roomTypers.isEmpty) {
        updated.remove(roomId);
      } else {
        updated[roomId] = roomTypers;
      }
      state = state.copyWith(typingUsers: updated);
    } catch (e) {
      debugPrint('[Chat] Error handling stop-typing event: $e');
    }
  }

  void _onUserOnline(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final userId = map['userId'] as String;
      state = state.copyWith(
        onlineUsers: {...state.onlineUsers, userId},
      );
    } catch (e) {
      debugPrint('[Chat] Error handling user:online event: $e');
    }
  }

  void _onUserOffline(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final userId = map['userId'] as String;
      final updated = Set<String>.from(state.onlineUsers);
      updated.remove(userId);
      state = state.copyWith(onlineUsers: updated);
    } catch (e) {
      debugPrint('[Chat] Error handling user:offline event: $e');
    }
  }

  void _onMessageRead(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final roomId = map['roomId'] as String;
      final readerId = map['userId'] as String;

      // Mark all messages in this room from us as read
      final currentUserId = _ref.read(currentUserProvider)?.id;
      if (currentUserId == null) return;

      final updatedMessages = state.messages.map((msg) {
        if (msg.chatRoomId == roomId &&
            msg.senderId == currentUserId &&
            !msg.isRead) {
          return msg.copyWith(isRead: true);
        }
        return msg;
      }).toList();

      if (state.currentRoomId == roomId) {
        state = state.copyWith(messages: updatedMessages);
      }

      debugPrint('[Chat] Messages read by $readerId in room $roomId');
    } catch (e) {
      debugPrint('[Chat] Error handling message:read event: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Room management
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> loadRooms() async {
    state = state.copyWith(isLoadingRooms: true, clearError: true);
    try {
      final rooms = await _repository.getChatRooms();
      state = state.copyWith(rooms: rooms, isLoadingRooms: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingRooms: false,
        error: 'فشل تحميل المحادثات',
      );
    }
  }

  Future<String> createOrGetRoom(String otherUserId) async {
    try {
      final room = await _repository.createOrGetRoom(otherUserId);

      // Add or update in list
      final exists = state.rooms.any((r) => r.id == room.id);
      final updatedRooms = exists
          ? state.rooms
          : [room, ...state.rooms];

      state = state.copyWith(rooms: updatedRooms);
      return room.id;
    } catch (e) {
      state = state.copyWith(error: 'فشل إنشاء المحادثة');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Enter / Leave room
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> enterRoom(String roomId) async {
    state = state.copyWith(
      currentRoomId: roomId,
      messages: [],
      currentPage: 1,
      hasMoreMessages: true,
    );

    _socket?.emit('join:room', {'roomId': roomId});
    await loadMessages(roomId, page: 1);
    await markAsRead(roomId);
  }

  void leaveRoom() {
    final roomId = state.currentRoomId;
    if (roomId != null) {
      _stopTypingImmediately(roomId);
    }
    state = state.copyWith(
      clearCurrentRoom: true,
      messages: [],
      currentPage: 1,
      hasMoreMessages: true,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Messages
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> loadMessages(String roomId, {int page = 1}) async {
    if (state.isLoadingMessages) return;
    state = state.copyWith(isLoadingMessages: true);
    try {
      final messages =
          await _repository.getMessages(roomId, page: page, limit: 30);

      final hasMore = messages.length == 30;

      if (page == 1) {
        state = state.copyWith(
          messages: messages,
          currentPage: 1,
          hasMoreMessages: hasMore,
          isLoadingMessages: false,
        );
      } else {
        // Prepend older messages at the top
        final combined = [...messages, ...state.messages];
        state = state.copyWith(
          messages: combined,
          currentPage: page,
          hasMoreMessages: hasMore,
          isLoadingMessages: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingMessages: false,
        error: 'فشل تحميل الرسائل',
      );
    }
  }

  Future<void> loadMoreMessages() async {
    if (!state.hasMoreMessages || state.isLoadingMessages) return;
    final roomId = state.currentRoomId;
    if (roomId == null) return;
    await loadMessages(roomId, page: state.currentPage + 1);
  }

  Future<void> sendMessage(String content) async {
    final roomId = state.currentRoomId;
    if (roomId == null || content.trim().isEmpty) return;

    _stopTypingImmediately(roomId);
    state = state.copyWith(isSending: true);

    try {
      // Optimistic message (will be replaced by real one from socket)
      final currentUser = _ref.read(currentUserProvider);
      final optimistic = Message(
        id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
        chatRoomId: roomId,
        senderId: currentUser?.id ?? '',
        content: content.trim(),
        type: MessageType.text,
        isRead: false,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, optimistic],
        isSending: false,
      );

      // Also emit via socket for real-time delivery
      _socket?.emit('send:message', {
        'roomId': roomId,
        'content': content.trim(),
        'type': 'text',
      });

      // Persist via REST as well (reliable delivery)
      final saved = await _repository.sendMessage(roomId, content.trim());

      // Replace optimistic with real message
      final updated = state.messages
          .map((m) => m.id == optimistic.id ? saved : m)
          .toList();
      state = state.copyWith(messages: updated);

      // Update room last message
      final updatedRooms = state.rooms.map((room) {
        if (room.id == roomId) {
          return room.copyWith(lastMessage: saved);
        }
        return room;
      }).toList();
      state = state.copyWith(rooms: updatedRooms);
    } catch (e) {
      // Remove optimistic message on failure
      final cleaned = state.messages
          .where((m) => !m.id.startsWith('optimistic_'))
          .toList();
      state = state.copyWith(
        messages: cleaned,
        isSending: false,
        error: 'فشل إرسال الرسالة',
      );
    }
  }

  Future<void> markAsRead(String roomId) async {
    try {
      await _repository.markAsRead(roomId);
      _socket?.emit('mark:read', {'roomId': roomId});

      // Reset unread count locally
      final updated = state.rooms.map((room) {
        if (room.id == roomId) {
          return room.copyWith(unreadCount: 0);
        }
        return room;
      }).toList();
      state = state.copyWith(rooms: updated);
    } catch (e) {
      debugPrint('[Chat] markAsRead error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Typing indicators
  // ──────────────────────────────────────────────────────────────────────────

  void onUserTyping(String roomId) {
    _typingTimer?.cancel();
    _socket?.emit('typing:start', {'roomId': roomId});

    // Auto stop after 3 seconds of inactivity
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _stopTypingImmediately(roomId);
    });
  }

  void onUserStopTyping(String roomId) {
    _typingTimer?.cancel();
    _stopTypingImmediately(roomId);
  }

  void _stopTypingImmediately(String roomId) {
    _socket?.emit('typing:stop', {'roomId': roomId});
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Search rooms (client-side filter)
  // ──────────────────────────────────────────────────────────────────────────

  List<ChatRoom> searchRooms(String query) {
    if (query.trim().isEmpty) return state.rooms;
    final q = query.toLowerCase();
    return state.rooms.where((room) {
      return room.otherUserName.toLowerCase().contains(q) ||
          (room.lastMessage?.content.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    _typingTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
