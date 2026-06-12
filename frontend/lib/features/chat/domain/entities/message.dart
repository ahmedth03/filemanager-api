import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('file')
  file,
}

@freezed
class Message with _$Message {
  const Message._();

  const factory Message({
    required String id,
    required String chatRoomId,
    required String senderId,
    required String content,
    @Default(MessageType.text) MessageType type,
    @Default(false) bool isRead,
    required DateTime createdAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  bool get isImage => type == MessageType.image;
  bool get isFile => type == MessageType.file;
  bool get isText => type == MessageType.text;
}
