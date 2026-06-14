import '../../../core/network/dio_client.dart';
import 'chat_model.dart';

class ChatRepository {
  Future<List<ChatRoomModel>> getRooms() async {
    final response = await DioClient.instance.get('/chat/rooms');
    final List data = response.data['data'] ?? response.data ?? [];
    return data.map((e) => ChatRoomModel.fromJson(e)).toList();
  }

  Future<ChatRoomModel> getOrCreateRoom(String otherUserId, {String? listingId}) async {
    final response = await DioClient.instance.post('/chat/rooms', data: {
      'memberIds': [otherUserId],
      if (listingId != null) 'listingId': listingId,
      'isGroup': false,
    });
    final data = response.data['data'] ?? response.data;
    return ChatRoomModel.fromJson(data);
  }

  Future<List<MessageModel>> getMessages(String roomId, {int page = 1}) async {
    final response = await DioClient.instance
        .get('/chat/rooms/$roomId/messages?page=$page&limit=50');
    final raw = response.data['data'] ?? response.data;
    final List list = raw['data'] ?? raw ?? [];
    return list.map((e) => MessageModel.fromJson(e)).toList();
  }

  Future<MessageModel> sendMessage(String roomId, String content) async {
    final response = await DioClient.instance
        .post('/chat/rooms/$roomId/messages', data: {'content': content});
    final data = response.data['data'] ?? response.data;
    return MessageModel.fromJson(data);
  }

  Future<void> markRead(String roomId) async {
    await DioClient.instance.patch('/chat/rooms/$roomId/read');
  }
}
