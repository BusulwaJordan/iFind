import 'package:flutter/foundation.dart';
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
    // Check direction A → B
    final r1 = await supabaseClient
        .from('chats')
        .select()
        .eq('business_a_id', businessId)
        .eq('business_b_id', partnerBusinessId)
        .maybeSingle();
    if (r1 != null) return ChatModel.fromJson(r1).toEntity();

    // Check direction B → A
    final r2 = await supabaseClient
        .from('chats')
        .select()
        .eq('business_a_id', partnerBusinessId)
        .eq('business_b_id', businessId)
        .maybeSingle();
    if (r2 != null) return ChatModel.fromJson(r2).toEntity();

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
      await supabaseClient.from('chats').update({
        'last_message': content,
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);
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
      final myBusinesses = await _getBusinessesOwnedBy(userId);

      // chats.business_id is UUID type (B2C) → use the UUID primary key
      final businessUUIDs = myBusinesses
          .map((b) => b['id']?.toString())
          .whereType<String>()
          .toList();
      // chats.business_a_id / business_b_id are TEXT type (B2B) → use custom string id
      final businessCustomIds = myBusinesses
          .map((b) => (b['business_id'] ?? b['id'])?.toString())
          .whereType<String>()
          .toList();
      final myBizIds = businessCustomIds.toSet();

      // Build OR filter — no embedded joins to avoid FK dependency issues
      final filters = <String>['customer_id.eq.$userId'];
      for (final uuid in businessUUIDs) {
        filters.add('business_id.eq.$uuid');       // UUID column (B2C)
      }
      for (final customId in businessCustomIds) {
        filters.add('business_a_id.eq.$customId'); // TEXT column (B2B)
        filters.add('business_b_id.eq.$customId');
      }

      final response = await supabaseClient
          .from('chats')
          .select('*')
          .or(filters.join(','))
          .order('last_message_at', ascending: false)
          .limit(50);

      final chatEntities = (response as List)
          .map((json) => ChatModel.fromJson(json).toEntity())
          .toList();

      // B2C: chat.businessId is a UUID — look up by businesses.id
      final b2cBizUUIDs = chatEntities
          .where((c) => !c.isB2B && c.businessId != null)
          .map((c) => c.businessId!)
          .toSet();

      // B2B: chat.businessAId/businessBId are TEXT (BIZ0122) — look up by businesses.business_id
      final b2bPartnerCustomIds = chatEntities
          .where((c) => c.isB2B)
          .map((c) => myBizIds.contains(c.businessAId) ? c.businessBId : c.businessAId)
          .whereType<String>()
          .toSet();

      // Customer IDs to fetch names for (when current user is the business owner)
      final customerIdsToFetch = chatEntities
          .where((c) => !c.isB2B && c.customerId != null && c.customerId != userId)
          .map((c) => c.customerId!)
          .toSet();

      // Fetch B2C business info keyed by UUID
      final b2cBizMap = <String, Map<String, dynamic>>{};
      if (b2cBizUUIDs.isNotEmpty) {
        final r = await supabaseClient
            .from('businesses')
            .select('id, name, logo_url')
            .inFilter('id', b2cBizUUIDs.toList());
        for (final b in (r as List)) {
          b2cBizMap[b['id'] as String] = Map<String, dynamic>.from(b as Map);
        }
      }

      // Fetch B2B partner business info keyed by custom business_id string
      final b2bBizMap = <String, Map<String, dynamic>>{};
      if (b2bPartnerCustomIds.isNotEmpty) {
        final r = await supabaseClient
            .from('businesses')
            .select('business_id, name, logo_url')
            .inFilter('business_id', b2bPartnerCustomIds.toList());
        for (final b in (r as List)) {
          b2bBizMap[b['business_id'] as String] =
              Map<String, dynamic>.from(b as Map);
        }
      }

      // Fetch customer names for business-owner view
      final customerMap = <String, Map<String, dynamic>>{};
      if (customerIdsToFetch.isNotEmpty) {
        final r = await supabaseClient
            .from('users')
            .select('id, full_name, avatar_url')
            .inFilter('id', customerIdsToFetch.toList());
        for (final u in (r as List)) {
          customerMap[u['id'] as String] =
              Map<String, dynamic>.from(u as Map);
        }
      }

      // Enrich each chat with resolved names/logos
      return chatEntities.map((chat) {
        if (chat.isB2B) {
          final partnerBizId = myBizIds.contains(chat.businessAId)
              ? chat.businessBId
              : chat.businessAId;
          final data = partnerBizId != null ? b2bBizMap[partnerBizId] : null;
          return chat.copyWith(
            partnerBusinessName: data?['name'] as String?,
            partnerBusinessLogo: data?['logo_url'] as String?,
          );
        } else {
          final bizData = chat.businessId != null ? b2cBizMap[chat.businessId!] : null;
          final customerData =
              chat.customerId != null ? customerMap[chat.customerId!] : null;
          return chat.copyWith(
            businessName: bizData?['name'] as String?,
            businessLogoUrl: bizData?['logo_url'] as String?,
            customerName: customerData?['full_name'] as String?,
            customerAvatarUrl: customerData?['avatar_url'] as String?,
          );
        }
      }).toList();
    } catch (e, st) {
      debugPrint('getMyChats error: $e\n$st');
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
          .select('*, users:customer_id(full_name, avatar_url)')
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