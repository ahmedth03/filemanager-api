import '../entities/chat_room.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  /// Fetch all chat rooms for the authenticated user.
  Future<List<ChatRoom>> getChatRooms();

  /// Fetch paginated messages for a given room.
  Future<List<Message>> getMessages(String roomId, {int page = 1, int limit = 30});

  /// Send a text (or media) message to a room.
  Future<Message> sendMessage(String roomId, String content, {MessageType type = MessageType.text});

  /// Mark all messages in a room as read.
  Future<void> markAsRead(String roomId);

  /// Create or retrieve an existing room with another user.
  Future<ChatRoom> createOrGetRoom(String otherUserId);

  /// Delete a message by ID (own messages only).
  Future<void> deleteMessage(String roomId, String messageId);
}
