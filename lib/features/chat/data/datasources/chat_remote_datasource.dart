import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRemoteDataSource {
  final SupabaseClient supabaseClient;

  ChatRemoteDataSource({required this.supabaseClient});

  /// Get or create a chat between customer and business
  Future<Map<String, dynamic>> getOrCreateChat({
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

      if (existingChat != null) return existingChat;

      // Create new
      return await supabaseClient.from('chats').insert({
        'customer_id': customerId,
        'business_id': businessId,
      }).select().single();
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
  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    try {
      return await supabaseClient
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  /// Stream messages for real-time updates
  Stream<List<Map<String, dynamic>>> streamMessages(String chatId) {
    return supabaseClient
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);
  }

  /// Fetch user-specific chats
  Future<List<Map<String, dynamic>>> getMyChats(String userId) async {
    try {
      // 1. Get businesses owned by this user
      final myBusinesses = await supabaseClient
          .from('businesses')
          .select('id')
          .eq('owner_id', userId);
      
      final businessIds = (myBusinesses as List).map((b) => b['id'].toString()).toList();

      // 2. Fetch chats where user is customer OR matches one of their business IDs
      var query = supabaseClient
          .from('chats')
          .select('*, businesses(*)');

      if (businessIds.isEmpty) {
        query = query.eq('customer_id', userId);
      } else {
        // Construct OR filter: customer_id is user OR business_id is one of theirs
        final bizFilter = businessIds.map((id) => 'business_id.eq.$id').join(',');
        query = query.or('customer_id.eq.$userId,$bizFilter');
      }

      return await query.order('last_message_at', ascending: false);
    } catch (e) {
      throw Exception('Failed to fetch chats: $e');
    }
  }
}
