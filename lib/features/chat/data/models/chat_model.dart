import 'package:ifind/features/chat/domain/entities/chat.dart';

class ChatModel extends Chat {
  const ChatModel({
    required super.id,
    required super.customerId,
    required super.businessId,
    super.lastMessage,
    super.lastMessageAt,
    required super.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      customerId: json['customer_id'],
      businessId: json['business_id'],
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null ? DateTime.parse(json['last_message_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'business_id': businessId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.content,
    super.isRead,
    required super.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      content: json['content'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
