import 'package:freezed_annotation/freezed_annotation.dart';

import 'message.dart';

part 'chat_room.freezed.dart';
part 'chat_room.g.dart';

@freezed
class ChatRoom with _$ChatRoom {
  const ChatRoom._();

  const factory ChatRoom({
    required String id,
    required List<String> participants,
    Message? lastMessage,
    @Default(0) int unreadCount,
    required DateTime updatedAt,
    // Other user info
    required String otherUserName,
    String? otherUserAvatar,
    String? otherUserPhone,
  }) = _ChatRoom;

  factory ChatRoom.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomFromJson(json);

  bool get hasUnread => unreadCount > 0;
}
