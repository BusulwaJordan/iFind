import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/chat/data/models/chat_model.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';
import 'package:uuid/uuid.dart';

class ChatRemoteDataSource {
  final SupabaseClient supabaseClient;

  ChatRemoteDataSource({required this.supabaseClient});

  // ---- B2C (Customer <-> Business) ----

  /// Get or create a chat between a customer and a business.
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
            'is_b2b': false,
          })
          .select()
          .single();

      return ChatModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to get/create chat: $e');
    }
  }

  // ---- B2B (Business <-> Business) ----

  /// Creates or retrieves an existing chat between two businesses.
  Future<Chat> getOrCreateB2BChat({
    required String businessId,
    required String partnerBusinessId,
  }) async {
    // 1. Check if a chat already exists (either direction)
    final existing = await _findExistingB2BChat(
      businessId: businessId,
      partnerBusinessId: partnerBusinessId,
    );
    if (existing != null) return existing;

    // 2. Create a new B2B chat
    final chatId = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    final data = {
      'id': chatId,
      'business_a_id': businessId,
      'business_b_id': partnerBusinessId,
      'is_b2b': true,
      'created_at': now,
      'updated_at': now,
      'last_message_at': now,
      // The original columns are set to null for B2B chats
      'customer_id': null,
      'business_id': null,
    };

    final response = await supabaseClient
        .from('chats')
        .insert(data)
        .select()
        .single();

    return ChatModel.fromJson(response).toEntity();
  }

  /// Helper to find an existing B2B chat (both directions)
  Future<Chat?> _findExistingB2BChat({
    required String businessId,
    required String partnerBusinessId,
  }) async {
    final response = await supabaseClient
        .from('chats')
        .select()
        .or(
          'and(business_a_id.eq.$businessId,business_b_id.eq.$partnerBusinessId),'
          'and(business_a_id.eq.$partnerBusinessId,business_b_id.eq.$businessId)'
        )
        .maybeSingle();

    if (response != null) {
      return ChatModel.fromJson(response).toEntity();
    }
    return null;
  }

  // ---- Common chat methods ----

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

  /// Fetch user-specific chats (B2C + B2B)
  Future<List<Chat>> getMyChats(String userId) async {
    try {
      // 1. Get businesses owned by this user
      final myBusinesses = await _getBusinessesOwnedBy(userId);
      final businessIds = myBusinesses
          .map((b) => (b['business_id'] ?? b['id']).toString())
          .toList();

      // 2. Build query: B2C chats where customer_id = userId OR business_id in my business IDs
      //    OR B2B chats where business_a_id or business_b_id in my business IDs.
      var query = supabaseClient.from('chats').select('*, businesses(name, logo_url), profiles:customer_id(full_name)');

      List<String> filters = [];

      // B2C: customer is me
      filters.add('customer_id.eq.$userId');

      // B2C: business is one of mine
      if (businessIds.isNotEmpty) {
        final bizFilter = businessIds.map((id) => 'business_id.eq.$id').join(',');
        filters.add(bizFilter);
      }

      // B2B: I am business_a or business_b
      if (businessIds.isNotEmpty) {
        final b2bFilterA = businessIds.map((id) => 'business_a_id.eq.$id').join(',');
        final b2bFilterB = businessIds.map((id) => 'business_b_id.eq.$id').join(',');
        if (b2bFilterA.isNotEmpty) filters.add(b2bFilterA);
        if (b2bFilterB.isNotEmpty) filters.add(b2bFilterB);
      }

      // Combine with OR
      final combinedFilter = filters.join(',');
      final response = await query
          .or(combinedFilter)
          .order('last_message_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => ChatModel.fromSupabase(json, myId: userId).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch chats: $e');
    }
  }

  /// Fetch all chats for a specific business (business owner view – B2C only)
  Future<List<Chat>> getChatsForBusiness({
    required String businessId,
    required String ownerId,
  }) async {
    try {
      final response = await supabaseClient
          .from('chats')
          .select('*, profiles:customer_id(full_name, avatar_url)')
          .eq('business_id', businessId)
          .order('last_message_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => ChatModel.fromSupabase(json, myId: ownerId).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch business chats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getBusinessesOwnedBy(String userId) async {
    try {
      final response = await supabaseClient
          .from('businesses')
          .select('id, business_id')
          .eq('owner_id', userId);
      return (response as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (_) {
      final response = await supabaseClient
          .from('businesses')
          .select('business_id')
          .eq('owner_id', userId);
      return (response as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
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