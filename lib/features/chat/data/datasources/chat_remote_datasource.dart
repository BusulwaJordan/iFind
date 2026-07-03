import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/services/interaction_service.dart';
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
      final ownedBusinesses = await _getBusinessesOwnedBy(customerId);
      final ownsThisBusiness = ownedBusinesses.any(
        (b) => (b['business_id'] ?? b['id'])?.toString() == businessId,
      );
      if (ownsThisBusiness) {
        throw Exception('You cannot message your own business');
      }

      // Try to fetch existing. Use limit(1) instead of maybeSingle() —
      // maybeSingle() throws if more than one row matches, and legacy
      // duplicate chat rows (from before earlier chats-schema fixes) would
      // make this fail for specific businesses instead of just reusing
      // the oldest chat.
      final existingChats = await supabaseClient
          .from('chats')
          .select()
          .eq('customer_id', customerId)
          .eq('business_id', businessId)
          .order('created_at', ascending: true)
          .limit(1);

      if (existingChats.isNotEmpty) {
        return ChatModel.fromJson(existingChats.first).toEntity();
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
      debugPrint('getOrCreateChat error: customerId=$customerId businessId=$businessId error=$e');
      throw Exception('Failed to get/create chat: $e');
    }
  }

  // ---- B2B (Business <-> Business) ----

  /// Creates or retrieves an existing chat between two businesses.
  Future<Chat> getOrCreateB2BChat({
    required String businessId,
    required String partnerBusinessId,
  }) async {
    if (businessId == partnerBusinessId) {
      throw Exception('A business cannot start a B2B chat with itself');
    }

    debugPrint('getOrCreateB2BChat: businessId=$businessId partnerBusinessId=$partnerBusinessId');

    // 1. Check if a chat already exists (either direction)
    final existing = await _findExistingB2BChat(
      businessId: businessId,
      partnerBusinessId: partnerBusinessId,
    );
    if (existing != null) {
      debugPrint('getOrCreateB2BChat: reusing existing chat id=${existing.id}');
      return existing;
    }

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

    debugPrint('getOrCreateB2BChat: no existing chat found, creating new chat id=$chatId');

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
    debugPrint('_findExistingB2BChat A->B: business_a_id=$businessId business_b_id=$partnerBusinessId -> ${r1?['id']}');
    if (r1 != null) return ChatModel.fromJson(r1).toEntity();

    // Check direction B → A
    final r2 = await supabaseClient
        .from('chats')
        .select()
        .eq('business_a_id', partnerBusinessId)
        .eq('business_b_id', businessId)
        .maybeSingle();
    debugPrint('_findExistingB2BChat B->A: business_a_id=$partnerBusinessId business_b_id=$businessId -> ${r2?['id']}');
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
    } catch (e) {
      debugPrint('sendMessage INSERT error (code=${_pgCode(e)}): chatId=$chatId senderId=$senderId error=$e');
      throw Exception('Failed to send message: $e');
    }
    try {
      await supabaseClient.from('chats').update({
        'last_message': content,
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);
    } catch (e) {
      // Non-fatal: message was sent, just the preview won't update immediately
      debugPrint('sendMessage chat UPDATE error (code=${_pgCode(e)}): $e');
    }

    unawaited(_logInquiryIfCustomerMessage(chatId: chatId, senderId: senderId));
  }

  /// Counts a message as an inquiry only when a customer messages a business
  /// (B2C) — a business replying to a lead, or B2B messages, don't count.
  Future<void> _logInquiryIfCustomerMessage({
    required String chatId,
    required String senderId,
  }) async {
    try {
      final chat = await supabaseClient
          .from('chats')
          .select('customer_id, business_id, is_b2b')
          .eq('id', chatId)
          .maybeSingle();
      if (chat == null) return;

      final isB2B = chat['is_b2b'] as bool? ?? false;
      final customerId = chat['customer_id'] as String?;
      final businessId = chat['business_id'] as String?;
      if (isB2B || customerId == null || businessId == null) return;
      if (senderId != customerId) return;

      await InteractionService(supabaseClient).logInteraction(
        userId: senderId,
        businessId: businessId,
        type: InteractionType.inquirySent,
      );
    } catch (_) {
      // Best-effort analytics tracking; never block messaging on this.
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

      // All chat business columns are TEXT — use the custom string id (e.g. BIZ0122)
      final businessCustomIds = myBusinesses
          .map((b) => (b['business_id'] ?? b['id'])?.toString())
          .whereType<String>()
          .toList();
      final myBizIds = businessCustomIds.toSet();

      // Build OR filter — no embedded joins to avoid FK dependency issues
      final filters = <String>['customer_id.eq.$userId'];
      for (final customId in businessCustomIds) {
        filters.add('business_id.eq.$customId');   // TEXT column (B2C)
        filters.add('business_a_id.eq.$customId'); // TEXT column (B2B)
        filters.add('business_b_id.eq.$customId');
      }

      final response = await supabaseClient
          .from('chats')
          .select('*')
          .or(filters.join(','))
          .order('last_message_at', ascending: false)
          .limit(50);

      // Exclude leftover self-chats (e.g. from before self-messaging was
      // blocked) where this user is both the customer and the business owner.
      final chatEntities = (response as List)
          .map((json) => ChatModel.fromJson(json).toEntity())
          .where((c) =>
              !(!c.isB2B && c.customerId == userId && myBizIds.contains(c.businessId)))
          .toList();

      // All business ID columns in chats are TEXT — collect custom IDs for lookup
      final allBizCustomIds = <String>{};
      for (final chat in chatEntities) {
        if (chat.isB2B) {
          final partnerBizId = myBizIds.contains(chat.businessAId)
              ? chat.businessBId
              : chat.businessAId;
          if (partnerBizId != null) allBizCustomIds.add(partnerBizId);
        } else {
          if (chat.businessId != null) allBizCustomIds.add(chat.businessId!);
        }
      }

      // Customer IDs to fetch — include all B2C chats regardless of who is viewing
      final customerIdsToFetch = chatEntities
          .where((c) => !c.isB2B && c.customerId != null)
          .map((c) => c.customerId!)
          .toSet();

      // Fetch all business names/logos keyed by business_id (custom string)
      final bizMap = <String, Map<String, dynamic>>{};
      if (allBizCustomIds.isNotEmpty) {
        final r = await supabaseClient
            .from('businesses')
            .select('business_id, name, logo_url')
            .inFilter('business_id', allBizCustomIds.toList());
        for (final b in (r as List)) {
          bizMap[b['business_id'] as String] =
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
          final data = partnerBizId != null ? bizMap[partnerBizId] : null;
          return chat.copyWith(
            partnerBusinessName: data?['name'] as String?,
            partnerBusinessLogo: data?['logo_url'] as String?,
          );
        } else {
          final isOwner = myBizIds.contains(chat.businessId);
          if (isOwner) {
            // Viewer is the business owner — other party is the customer
            final customerData =
                chat.customerId != null ? customerMap[chat.customerId!] : null;
            return chat.copyWith(
              customerName: customerData?['full_name'] as String?,
              customerAvatarUrl: customerData?['avatar_url'] as String?,
            );
          } else {
            // Viewer is the customer — other party is the business
            final bizData =
                chat.businessId != null ? bizMap[chat.businessId!] : null;
            return chat.copyWith(
              businessName: bizData?['name'] as String?,
              businessLogoUrl: bizData?['logo_url'] as String?,
            );
          }
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
          .select('*')
          .eq('business_id', businessId)
          .order('last_message_at', ascending: false)
          .limit(50);

      // Exclude leftover self-chats (e.g. from before self-messaging was
      // blocked) where the "customer" is actually the business owner.
      final chats = (response as List)
          .map((json) => ChatModel.fromJson(json).toEntity())
          .where((c) => c.customerId != ownerId)
          .toList();

      // Fetch customer names separately
      final customerIds = chats
          .where((c) => c.customerId != null)
          .map((c) => c.customerId!)
          .toSet()
          .toList();
      final customerMap = <String, Map<String, dynamic>>{};
      if (customerIds.isNotEmpty) {
        final r = await supabaseClient
            .from('users')
            .select('id, full_name, avatar_url')
            .inFilter('id', customerIds);
        for (final u in (r as List)) {
          customerMap[u['id'] as String] =
              Map<String, dynamic>.from(u as Map);
        }
      }

      return chats.map((chat) {
        final customerData =
            chat.customerId != null ? customerMap[chat.customerId!] : null;
        return chat.copyWith(
          customerName: customerData?['full_name'] as String?,
          customerAvatarUrl: customerData?['avatar_url'] as String?,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch business chats: $e');
    }
  }

  /// Returns the sender_id of the most recent message for each chat id.
  Future<Map<String, String>> getLastMessageSenders({
    required List<String> chatIds,
  }) async {
    if (chatIds.isEmpty) return {};
    try {
      final rows = await supabaseClient
          .from('messages')
          .select('chat_id, sender_id, created_at')
          .inFilter('chat_id', chatIds)
          .order('created_at', ascending: false);

      final result = <String, String>{};
      for (final row in (rows as List)) {
        final chatId = row['chat_id'] as String;
        // Rows are newest-first, so the first occurrence per chat_id is the latest.
        result.putIfAbsent(chatId, () => row['sender_id'] as String);
      }
      return result;
    } catch (_) {
      return {};
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

  String _pgCode(Object e) {
    final s = e.toString();
    final match = RegExp(r'code:\s*(\w+)').firstMatch(s);
    return match?.group(1) ?? 'unknown';
  }
}