import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(
      supabaseClient: ref.watch(supabaseClientProvider));
});

/// My Chats Provider
final myChatsProvider = FutureProvider<List<Chat>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final dataSource = ref.watch(chatRemoteDataSourceProvider);
  return await dataSource.getMyChats(user.id);
});

/// Messages Stream Provider
final messagesStreamProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  final dataSource = ref.watch(chatRemoteDataSourceProvider);
  return dataSource.streamMessages(chatId);
});

/// Chats for a specific business (used by business owners in Inquiries screen)
final businessChatsProvider =
    FutureProvider.family.autoDispose<List<Chat>, String>((ref, businessId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final dataSource = ref.watch(chatRemoteDataSourceProvider);
  return dataSource.getChatsForBusiness(businessId: businessId, ownerId: user.id);
});

/// Chats where the customer's message is still unanswered — the customer
/// sent the most recent message and the business hasn't replied yet. Used
/// for the Leads Dashboard "Contacts" section: a chat drops out of this list
/// as soon as the business sends a reply.
final unansweredContactsProvider =
    FutureProvider.family.autoDispose<List<Chat>, String>((ref, businessId) async {
  final chats = await ref.watch(businessChatsProvider(businessId).future);
  if (chats.isEmpty) return [];

  final dataSource = ref.watch(chatRemoteDataSourceProvider);
  final lastSenders =
      await dataSource.getLastMessageSenders(chatIds: chats.map((c) => c.id).toList());

  return chats.where((chat) {
    final lastSenderId = lastSenders[chat.id];
    return lastSenderId != null && lastSenderId == chat.customerId;
  }).toList();
});
