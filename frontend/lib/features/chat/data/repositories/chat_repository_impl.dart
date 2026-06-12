import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(chatRemoteDatasourceProvider));
});

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._datasource);

  final ChatRemoteDatasource _datasource;

  // ── Rooms ─────────────────────────────────────────────────────────────────

  @override
  Future<List<ChatRoom>> getChatRooms() => _datasource.getChatRooms();

  @override
  Future<ChatRoom> createOrGetRoom(String otherUserId) =>
      _datasource.createChatRoom(otherUserId);

  // ── Messages ──────────────────────────────────────────────────────────────

  @override
  Future<List<Message>> getMessages(
    String roomId, {
    int page = 1,
    int limit = 30,
  }) =>
      _datasource.getMessages(roomId, page);

  @override
  Future<Message> sendMessage(
    String roomId,
    String content, {
    MessageType type = MessageType.text,
  }) =>
      _datasource.sendMessage(roomId, content, type);

  @override
  Future<void> markAsRead(String roomId) => _datasource.markAsRead(roomId);

  @override
  Future<void> deleteMessage(String roomId, String messageId) =>
      _datasource.deleteMessage(roomId, messageId);
}
