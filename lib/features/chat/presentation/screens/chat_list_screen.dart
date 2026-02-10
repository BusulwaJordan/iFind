import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(myChatsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const EmptyStateWidget(
              title: 'No messages yet',
              message: 'Start a conversation with a shop or wait for customer inquiries here.',
              icon: Icons.forum_rounded,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myChatsProvider),
            child: ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
              itemBuilder: (context, index) {
                final chat = chats[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.primaryGreen),
                  ),
                  title: Text('Chat with Business', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  subtitle: Text(chat.lastMessage ?? 'No messages yet', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: chat.lastMessageAt != null 
                    ? Text(timeago.format(chat.lastMessageAt!, locale: 'en_short'), style: const TextStyle(fontSize: 10, color: Colors.grey))
                    : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        chat: chat,
                        otherPartyName: 'Business Name', // In a real app, join users table for this
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
