import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat.freezed.dart';

@freezed
class Chat with _$Chat {
  const factory Chat({
    required String id,
    // B2C fields (nullable for B2B)
    String? customerId,
    String? businessId,
    // B2B fields (nullable for B2C)
    String? businessAId,
    String? businessBId,
    // Flag to distinguish chat type
    @Default(false) bool isB2B,
    // Common fields
    String? lastMessage,
    DateTime? lastMessageAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    // Transient UI fields (for B2C)
    String? businessName,
    String? businessLogoUrl,
    String? customerName,
    String? customerAvatarUrl,
    // Transient UI fields (for B2B)
    String? partnerBusinessName,
    String? partnerBusinessLogo,
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