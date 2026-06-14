class ChatRoomModel {
  final String id;
  final List<ChatMemberModel> members;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool isGroup;

  const ChatRoomModel({
    required this.id,
    required this.members,
    this.lastMessage,
    this.lastMessageAt,
    required this.isGroup,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) => ChatRoomModel(
        id: json['id']?.toString() ?? '',
        members: (json['members'] as List? ?? [])
            .map((e) => ChatMemberModel.fromJson(e))
            .toList(),
        lastMessage: json['lastMessage'],
        lastMessageAt: json['lastMessageAt'] != null
            ? DateTime.parse(json['lastMessageAt'])
            : null,
        isGroup: json['isGroup'] ?? false,
      );
}

class ChatMemberModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  const ChatMemberModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ChatMemberModel.fromJson(Map<String, dynamic> json) => ChatMemberModel(
        id: json['id']?.toString() ?? '',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        avatarUrl: json['avatarUrl'],
      );
}

class MessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;

  const MessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    required this.status,
    required this.createdAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id']?.toString() ?? '',
        roomId: json['roomId']?.toString() ?? '',
        senderId: json['senderId']?.toString() ?? '',
        content: json['content'] ?? '',
        mediaUrl: json['mediaUrl'],
        status: json['status'] ?? 'SENT',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        sender: json['sender'],
      );
}
