import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

@freezed
@freezed
class ChatModel with _$ChatModel {
  const factory ChatModel({
    required String id,
    @JsonKey(name: 'customer_id') required String customerId,
    @JsonKey(name: 'business_id') required String businessId,
    @JsonKey(name: 'last_message') String? lastMessage,
    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    // Add transient fields from join
    @JsonKey(includeToJson: false, includeFromJson: false) String? businessName,
    @JsonKey(includeToJson: false, includeFromJson: false)
    String? businessLogoUrl,
  }) = _ChatModel;

  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);

  factory ChatModel.fromSupabase(Map<String, dynamic> json, {String? myId}) {
    // Handle Supabase returning join as either a single object or a list
    final businessData = json['businesses'];
    Map<String, dynamic>? businessMap;
    if (businessData is List && businessData.isNotEmpty) {
      businessMap = businessData.first;
    } else if (businessData is Map<String, dynamic>) {
      businessMap = businessData;
    }

    final profileData = json['profiles'];
    Map<String, dynamic>? profileMap;
    if (profileData is List && profileData.isNotEmpty) {
      profileMap = profileData.first;
    } else if (profileData is Map<String, dynamic>) {
      profileMap = profileData;
    }

    // IDENTITY RESOLUTION LOGIC:
    final customerId = json['customer_id'] as String;
    final isCustomer = myId == customerId;

    final String resolvedName;
    final String? resolvedLogo;

    if (isCustomer) {
      resolvedName = businessMap?['name'] as String? ?? 'Unknown Business';
      resolvedLogo = businessMap?['logo_url'] as String?;
    } else {
      resolvedName = profileMap?['full_name'] as String? ?? 'Customer';
      resolvedLogo = profileMap?['avatar_url'] as String?;
    }

    return ChatModel.fromJson(json).copyWith(
      businessName: resolvedName,
      businessLogoUrl: resolvedLogo,
    );
  }

  const ChatModel._();

  Chat toEntity() => Chat(
        id: id,
        customerId: customerId,
        businessId: businessId,
        lastMessage: lastMessage,
        lastMessageAt: lastMessageAt,
        createdAt: createdAt,
        businessName: businessName,
        businessLogoUrl: businessLogoUrl,
      );
}

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
