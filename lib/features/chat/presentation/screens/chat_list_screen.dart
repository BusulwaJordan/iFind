import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
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
                final businessName = chat.businessName ?? 'Unknown Business';
                
                return Dismissible(
                  key: Key('chat_${chat.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  ),
                  onDismissed: (_) {
                    ref.read(chatRemoteDataSourceProvider).deleteChat(chat.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Chat with $businessName deleted')),
                    );
                  },
                  child: ListTile(
                    leading: chat.businessLogoUrl != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(chat.businessLogoUrl!),
                            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                          )
                        : CircleAvatar(
                            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                            child: const Icon(Icons.storefront_rounded, color: AppColors.primaryGreen),
                          ),
                    title: Text(businessName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: Text(chat.lastMessage ?? 'No messages yet', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: chat.lastMessageAt != null 
                      ? Text(timeago.format(chat.lastMessageAt!, locale: 'en_short'), style: const TextStyle(fontSize: 10, color: Colors.grey))
                      : null,
                    onTap: () => context.push('/chat', extra: {
                        'chat': chat,
                        'otherPartyName': businessName,
                      }),
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
