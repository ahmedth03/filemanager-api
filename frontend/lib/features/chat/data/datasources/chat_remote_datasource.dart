import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final chatRemoteDatasourceProvider = Provider<ChatRemoteDatasource>((ref) {
  final dio = ref.watch(dioProvider);
  return ChatRemoteDatasourceImpl(dio);
});

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract interface class ChatRemoteDatasource {
  Future<List<ChatRoom>> getChatRooms();
  Future<List<Message>> getMessages(String roomId, int page);
  Future<Message> sendMessage(String roomId, String content, MessageType type);
  Future<void> markAsRead(String roomId);
  Future<ChatRoom> createChatRoom(String otherUserId);
  Future<void> deleteMessage(String roomId, String messageId);
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

class ChatRemoteDatasourceImpl implements ChatRemoteDatasource {
  ChatRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    final response = await _dio.get('/chat/rooms');
    final List<dynamic> data = response.data['data'] ?? response.data ?? [];
    return data
        .map((json) => ChatRoom.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Message>> getMessages(String roomId, int page) async {
    final response = await _dio.get(
      '/chat/rooms/$roomId/messages',
      queryParameters: {'page': page, 'limit': 30},
    );
    final List<dynamic> data = response.data['data'] ?? response.data ?? [];
    return data
        .map((json) => Message.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Message> sendMessage(
      String roomId, String content, MessageType type) async {
    final response = await _dio.post(
      '/chat/rooms/$roomId/messages',
      data: {
        'content': content,
        'type': type.name,
      },
    );
    final data = response.data['data'] ?? response.data;
    return Message.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> markAsRead(String roomId) async {
    await _dio.put('/chat/rooms/$roomId/read');
  }

  @override
  Future<ChatRoom> createChatRoom(String otherUserId) async {
    final response = await _dio.post(
      '/chat/rooms',
      data: {'otherUserId': otherUserId},
    );
    final data = response.data['data'] ?? response.data;
    return ChatRoom.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteMessage(String roomId, String messageId) async {
    await _dio.delete('/chat/rooms/$roomId/messages/$messageId');
  }
}
