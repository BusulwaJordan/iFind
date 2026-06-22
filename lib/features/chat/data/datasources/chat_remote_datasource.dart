import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/chat/data/models/chat_model.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';

class ChatRemoteDataSource {
  final SupabaseClient supabaseClient;

  ChatRemoteDataSource({required this.supabaseClient});

  /// Get or create a chat between customer and business
  Future<Chat> getOrCreateChat({
    required String customerId,
    required String businessId,
  }) async {
    try {
      // Try to fetch existing
      final existingChat = await supabaseClient
          .from('chats')
          .select()
          .eq('customer_id', customerId)
          .eq('business_id', businessId)
          .maybeSingle();

      if (existingChat != null) {
        return ChatModel.fromJson(existingChat).toEntity();
      }

      // Create new
      final response = await supabaseClient
          .from('chats')
          .insert({
            'customer_id': customerId,
            'business_id': businessId,
          })
          .select()
          .single();

      return ChatModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to get/create chat: $e');
    }
  }

  /// Send a message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    try {
      await supabaseClient.from('messages').insert({
        'chat_id': chatId,
        'sender_id': senderId,
        'content': content,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Fetch messages for a chat
  Future<List<Message>> getMessages(String chatId) async {
    try {
      final response = await supabaseClient
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => MessageModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  /// Stream messages for real-time updates
  Stream<List<Message>> streamMessages(String chatId) async* {
    while (true) {
      yield await getMessages(chatId);
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  /// Fetch user-specific chats
  Future<List<Chat>> getMyChats(String userId) async {
    try {
      // 1. Get businesses owned by this user
      final myBusinesses = await supabaseClient
          .from('businesses')
          .select('id')
          .eq('owner_id', userId);

      final businessIds =
          (myBusinesses as List).map((b) => b['id'].toString()).toList();

      // 2. Fetch chats with business AND customer info joined
      var query = supabaseClient.from('chats').select(
          '*, businesses(id, name, logo_url), profiles:customer_id(full_name)');

      if (businessIds.isEmpty) {
        query = query.eq('customer_id', userId);
      } else {
        // Construct OR filter: customer_id is user OR business_id is one of theirs
        final bizFilter =
            businessIds.map((id) => 'business_id.eq.$id').join(',');
        query = query.or('customer_id.eq.$userId,$bizFilter');
      }

      final List<dynamic> response =
          await query.order('last_message_at', ascending: false).limit(50);

      return response
          .map((json) => ChatModel.fromSupabase(json, myId: userId).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch chats: $e');
    }
  }

  /// Delete a chat and its messages
  Future<void> deleteChat(String chatId) async {
    try {
      await supabaseClient.from('chats').delete().eq('id', chatId);
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  /// Delete a single message
  Future<void> deleteMessage(String messageId) async {
    try {
      await supabaseClient.from('messages').delete().eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
}
