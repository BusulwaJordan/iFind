import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat.freezed.dart';

@freezed
class Chat with _$Chat {
  const factory Chat({
    required String id,
    required String customerId,
    required String businessId,
    String? lastMessage,
    DateTime? lastMessageAt,
    required DateTime createdAt,
    // Transient UI fields
    String? businessName,
    String? businessLogoUrl,
  }) = _Chat;
}

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String chatId,
    required String senderId,
    required String content,
    @Default(false) bool isRead,
    required DateTime createdAt,
  }) = _Message;
}
