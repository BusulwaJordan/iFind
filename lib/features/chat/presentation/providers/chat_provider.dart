import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(supabaseClient: ref.watch(supabaseClientProvider));
});

/// My Chats Provider
final myChatsProvider = FutureProvider<List<Chat>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final dataSource = ref.watch(chatRemoteDataSourceProvider);
  final data = await dataSource.getMyChats(user.id);
  
  return data.map((json) => Chat(
    id: json['id'],
    customerId: json['customer_id'],
    businessId: json['business_id'],
    lastMessage: json['last_message'],
    lastMessageAt: json['last_message_at'] != null ? DateTime.parse(json['last_message_at']) : null,
    createdAt: DateTime.parse(json['created_at']),
  )).toList();
});

/// Messages Stream Provider
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  final dataSource = ref.watch(chatRemoteDataSourceProvider);
  return dataSource.streamMessages(chatId).map((list) => list.map((json) => Message(
    id: json['id'],
    chatId: json['chat_id'],
    senderId: json['sender_id'],
    content: json['content'],
    isRead: json['is_read'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
  )).toList());
});
