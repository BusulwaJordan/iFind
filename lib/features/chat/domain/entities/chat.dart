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
    // The business_id "View Shop" should open for this chat, resolved
    // per-viewer: the partner's business for B2B, the shop for a customer's
    // B2C view, or the customer's own business (if they own one) for a
    // business owner's B2C view. Null when there's no business to show
    // (e.g. a plain customer with no business of their own).
    String? otherPartyBusinessId,
    // Number of messages in this chat sent by the other party that this
    // user hasn't read yet. Computed separately (not a raw chats column).
    @Default(0) int unreadCount,
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
