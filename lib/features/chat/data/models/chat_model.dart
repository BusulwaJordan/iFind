import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

@freezed
class ChatModel with _$ChatModel {
  const factory ChatModel({
    required String id,
    @JsonKey(name: 'customer_id') String? customerId, // Now nullable for B2B
    @JsonKey(name: 'business_id') String? businessId, // Now nullable for B2B
    @JsonKey(name: 'business_a_id') String? businessAId, // NEW: for B2B
    @JsonKey(name: 'business_b_id') String? businessBId, // NEW: for B2B
    @JsonKey(name: 'is_b2b') @Default(false) bool isB2B, // NEW: flag
    @JsonKey(name: 'last_message') String? lastMessage,
    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    // Transient fields for joined data
    @JsonKey(includeToJson: false, includeFromJson: false) String? businessName,
    @JsonKey(includeToJson: false, includeFromJson: false) String? businessLogoUrl,
    @JsonKey(includeToJson: false, includeFromJson: false) String? customerName,
    @JsonKey(includeToJson: false, includeFromJson: false) String? customerAvatarUrl,
    // For B2B partner business name/logo
    @JsonKey(includeToJson: false, includeFromJson: false) String? partnerBusinessName,
    @JsonKey(includeToJson: false, includeFromJson: false) String? partnerBusinessLogo,
  }) = _ChatModel;

  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);

  /// Creates a ChatModel from a Supabase response with joined data
  factory ChatModel.fromSupabase(Map<String, dynamic> json, {String? myId}) {
    // Extract business data (for B2C: the business table joined)
    final businessData = json['businesses'];
    Map<String, dynamic>? businessMap;
    if (businessData is List && businessData.isNotEmpty) {
      businessMap = businessData.first;
    } else if (businessData is Map<String, dynamic>) {
      businessMap = businessData;
    }

    // Extract profile data (for B2C: the customer profile)
    final profileData = json['users'];
    Map<String, dynamic>? profileMap;
    if (profileData is List && profileData.isNotEmpty) {
      profileMap = profileData.first;
    } else if (profileData is Map<String, dynamic>) {
      profileMap = profileData;
    }

    // Extract B2B partner data if available
    final partnerData = json['partner_business'];
    Map<String, dynamic>? partnerMap;
    if (partnerData is List && partnerData.isNotEmpty) {
      partnerMap = partnerData.first;
    } else if (partnerData is Map<String, dynamic>) {
      partnerMap = partnerData;
    }

    // Determine chat type and resolve display names
    final isB2B = json['is_b2b'] as bool? ?? false;

    String? resolvedBusinessName;
    String? resolvedBusinessLogo;
    String? resolvedCustomerName;
    String? resolvedCustomerAvatar;
    String? resolvedPartnerName;
    String? resolvedPartnerLogo;

    if (isB2B) {
      // B2B: we have business_a and business_b
      // We need to determine which is "my" business and which is the partner
      final businessAId = json['business_a_id'] as String?;
      final businessBId = json['business_b_id'] as String?;

      // If myId is provided, check if it matches either business A or B
      // This requires knowing which businesses the user owns
      // We'll fetch that from the context, but for now we'll use the map
      // For display, we'll try to use the partner business name from the joined data
      if (partnerMap != null) {
        resolvedPartnerName = partnerMap['name'] as String?;
        resolvedPartnerLogo = partnerMap['logo_url'] as String?;
      }
    } else {
      // B2C: resolve identity as before
      final customerId = json['customer_id'] as String;
      final isCustomer = myId == customerId;

      if (isCustomer) {
        resolvedBusinessName = businessMap?['name'] as String? ?? 'Unknown Business';
        resolvedBusinessLogo = businessMap?['logo_url'] as String?;
      } else {
        resolvedCustomerName = profileMap?['full_name'] as String? ?? 'Customer';
        resolvedCustomerAvatar = profileMap?['avatar_url'] as String?;
      }
    }

    return ChatModel.fromJson(json).copyWith(
      businessName: resolvedBusinessName,
      businessLogoUrl: resolvedBusinessLogo,
      customerName: resolvedCustomerName,
      customerAvatarUrl: resolvedCustomerAvatar,
      partnerBusinessName: resolvedPartnerName,
      partnerBusinessLogo: resolvedPartnerLogo,
    );
  }

  const ChatModel._();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'business_id': businessId,
      'business_a_id': businessAId,
      'business_b_id': businessBId,
      'is_b2b': isB2B,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Converts to the Chat entity
  Chat toEntity() => Chat(
        id: id,
        customerId: customerId,
        businessId: businessId,
        businessAId: businessAId,
        businessBId: businessBId,
        isB2B: isB2B,
        lastMessage: lastMessage,
        lastMessageAt: lastMessageAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        businessName: businessName,
        businessLogoUrl: businessLogoUrl,
        customerName: customerName,
        customerAvatarUrl: customerAvatarUrl,
        partnerBusinessName: partnerBusinessName,
        partnerBusinessLogo: partnerBusinessLogo,
      );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MessageModel (unchanged, but included for completeness)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    @JsonKey(name: 'chat_id') required String chatId,
    @JsonKey(name: 'sender_id') required String senderId,
    required String content,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  const MessageModel._();

  Message toEntity() => Message(
        id: id,
        chatId: chatId,
        senderId: senderId,
        content: content,
        isRead: isRead,
        createdAt: createdAt,
      );

  factory MessageModel.fromEntity(Message message) => MessageModel(
        id: message.id,
        chatId: message.chatId,
        senderId: message.senderId,
        content: message.content,
        isRead: message.isRead,
        createdAt: message.createdAt,
      );
}