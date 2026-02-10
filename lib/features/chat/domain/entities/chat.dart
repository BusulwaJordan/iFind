import 'package:equatable/equatable.dart';

class Chat extends Equatable {
  final String id;
  final String customerId;
  final String businessId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  const Chat({
    required this.id,
    required this.customerId,
    required this.businessId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, customerId, businessId, lastMessage, lastMessageAt];
}

class Message extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, chatId, senderId, content, isRead, createdAt];
}
