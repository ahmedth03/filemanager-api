import '../entities/chat_room.dart';
import '../entities/message.dart';

/// Contract for all chat data operations.
/// Implementations may use REST, WebSocket, or a combination.
abstract class ChatRepository {
  /// Fetch all chat rooms for the authenticated user, sorted newest-first.
  Future<List<ChatRoom>> getChatRooms();

  /// Fetch paginated messages for a given room.
  /// [page] is 1-indexed. [limit] controls page size (default 30).
  Future<List<Message>> getMessages(
    String roomId, {
    int page = 1,
    int limit = 30,
  });

  /// Send a text (or media) message to [roomId].
  /// Returns the persisted [Message] from the server.
  Future<Message> sendMessage(
    String roomId,
    String content, {
    MessageType type = MessageType.text,
  });

  /// Mark all unread messages in [roomId] as read.
  Future<void> markAsRead(String roomId);

  /// Create a new room or return the existing one between the current user
  /// and [otherUserId].
  Future<ChatRoom> createOrGetRoom(String otherUserId);

  /// Delete a message by [messageId] in [roomId].
  /// Only the sender may delete their own messages.
  Future<void> deleteMessage(String roomId, String messageId);
}
