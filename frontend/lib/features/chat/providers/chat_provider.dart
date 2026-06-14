import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/chat_repository.dart';
import '../data/chat_model.dart';

final chatRepositoryProvider =
    Provider<ChatRepository>((ref) => ChatRepository());

final chatRoomsProvider =
    FutureProvider.autoDispose<List<ChatRoomModel>>((ref) async {
  return ref.read(chatRepositoryProvider).getRooms();
});

class ChatMessagesNotifier extends StateNotifier<List<MessageModel>> {
  final ChatRepository _repo;
  final String roomId;

  ChatMessagesNotifier(this._repo, this.roomId) : super([]);

  Future<void> load() async {
    final messages = await _repo.getMessages(roomId);
    state = messages.reversed.toList();
  }

  Future<void> send(String content) async {
    final message = await _repo.sendMessage(roomId, content);
    state = [message, ...state];
  }

  void addMessage(MessageModel message) {
    if (!state.any((m) => m.id == message.id)) {
      state = [message, ...state];
    }
  }
}

final chatMessagesProvider = StateNotifierProvider.autoDispose
    .family<ChatMessagesNotifier, List<MessageModel>, String>((ref, roomId) {
  return ChatMessagesNotifier(ref.read(chatRepositoryProvider), roomId);
});
