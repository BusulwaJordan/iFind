import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends ConsumerWidget {
  static const _productInquiryPrefix = 'IFIND_PRODUCT_INQUIRY::';

  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(myChatsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // ── Hero Header ───────────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(36)),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 16, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF003D2B),
                      Color(0xFF006241),
                      Color(0xFF0B7A5A)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative bubble
                    Positioned(
                      top: -24,
                      right: -24,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.chat_bubble_rounded,
                                color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text('Messages',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900)),
                            const Spacer(),
                            // Refresh button
                            chatsAsync.when(
                              data: (chats) => _iconBtn(
                                Icons.refresh_rounded,
                                () => ref.refresh(myChatsProvider),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 6),
                        chatsAsync.when(
                          data: (chats) => Text(
                            chats.isEmpty
                                ? 'No conversations yet'
                                : '${chats.length} conversation${chats.length == 1 ? '' : 's'}',
                            style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ).animate().fadeIn(delay: 150.ms),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Chat List ─────────────────────────────────────────────────
            Expanded(
              child: chatsAsync.when(
                loading: () => const Center(child: IFindLoaderInline(size: 60)),
                error: (e, s) => ErrorRetryWidget(
                    message: friendlyError(e),
                    onRetry: () => ref.invalidate(myChatsProvider)),
                data: (chats) {
                  if (chats.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No messages yet',
                      message:
                          'Start a conversation with a business or wait for customer inquiries here.',
                      icon: Icons.forum_rounded,
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () async => ref.refresh(myChatsProvider),
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          MediaQuery.of(context).padding.bottom + 100),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final businessName =
                            chat.businessName ?? 'Unknown Business';
                        final initials = businessName.isNotEmpty
                            ? businessName[0].toUpperCase()
                            : 'B';

                        return Dismissible(
                          key: Key('chat_${chat.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            return showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: Text('Delete chat?',
                                    style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold)),
                                content: Text(
                                    'Remove your conversation with $businessName?',
                                    style: GoogleFonts.outfit()),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.only(right: 20),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.delete_rounded,
                                color: Colors.redAccent, size: 22),
                          ),
                          onDismissed: (_) async {
                            await ref
                                .read(chatRemoteDataSourceProvider)
                                .deleteChat(chat.id);
                            ref.invalidate(myChatsProvider);
                            if (context.mounted) {
                              AppToast.show(
                                  context,
                                  'Chat with $businessName deleted',
                                  type: ToastType.info);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3)),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              leading: chat.businessLogoUrl != null
                                  ? CircleAvatar(
                                      radius: 26,
                                      backgroundImage:
                                          NetworkImage(chat.businessLogoUrl!),
                                      backgroundColor: AppColors.primaryGreen
                                          .withValues(alpha: 0.1),
                                    )
                                  : CircleAvatar(
                                      radius: 26,
                                      backgroundColor: AppColors.primaryGreen
                                          .withValues(alpha: 0.12),
                                      child: Text(initials,
                                          style: GoogleFonts.outfit(
                                              color: AppColors.primaryGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ),
                              title: Text(businessName,
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                    _previewMessage(chat.lastMessage),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: Colors.grey.shade500)),
                              ),
                              trailing: chat.lastMessageAt != null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                            timeago.format(
                                                chat.lastMessageAt!,
                                                locale: 'en_short'),
                                            style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                color: Colors.grey.shade400)),
                                        const SizedBox(height: 6),
                                        const Icon(
                                            Icons.chevron_right_rounded,
                                            color: AppColors.primaryGreen,
                                            size: 18),
                                      ],
                                    )
                                  : null,
                              onTap: () => context.push('/chat', extra: {
                                'chat': chat,
                                'otherPartyName': businessName,
                              }),
                            ),
                          ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)).slideY(begin: 0.1),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  String _previewMessage(String? message) {
    if (message == null || message.trim().isEmpty) return 'No messages yet';

    if (message.startsWith(_productInquiryPrefix)) {
      try {
        final data =
            jsonDecode(message.substring(_productInquiryPrefix.length))
                as Map<String, dynamic>;
        final title = data['title'] as String? ?? 'product';
        return 'Product inquiry: $title';
      } catch (_) {
        return 'Product inquiry';
      }
    }

    if (message.startsWith('[MEDIA_INQUIRY]')) {
      final parts = message.split('|');
      if (parts.length > 3 && parts[3].trim().isNotEmpty) return parts[3];
      return 'Product inquiry';
    }

    return message;
  }
}
