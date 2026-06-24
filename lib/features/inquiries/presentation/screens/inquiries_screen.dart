import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class InquiriesScreen extends ConsumerWidget {
  const InquiriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final myBusinessesAsync = user != null
        ? ref.watch(myBusinessesProvider(user.id))
        : const AsyncValue<List<Business>>.data([]);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: AppColors.deepGreen,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.deepGreen, AppColors.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inbox_rounded,
                              color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'BUSINESS OWNER',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Customer Inquiries',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'View and respond to customer messages',
                        style: GoogleFonts.outfit(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (user == null)
            SliverFillRemaining(
              child: Center(
                child: Text('Please sign in to view inquiries.',
                    style: GoogleFonts.outfit(color: Colors.grey)),
              ),
            )
          else
            myBusinessesAsync.when(
              data: (businesses) {
                if (businesses.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.store_mall_directory_rounded,
                              size: 72, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No business profile found',
                            style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a business to start receiving inquiries.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                                fontSize: 14, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/create-business'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.add_business_rounded),
                            label: Text('Create Business',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return _InquiryList(businessId: businesses.first.id);
              },
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                child: ErrorRetryWidget(message: friendlyError(e)),
              ),
            ),
        ],
      ),
    );
  }
}

class _InquiryList extends ConsumerWidget {
  final String businessId;
  const _InquiryList({required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(businessChatsProvider(businessId));

    return chatsAsync.when(
      data: (chats) {
        if (chats.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No inquiries yet',
                    style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customer messages will appear here\nwhen they contact your business.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _InquiryTile(chat: chats[i])
                  .animate()
                  .fadeIn(delay: (i * 50).ms)
                  .slideX(begin: 0.1),
              childCount: chats.length,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          SliverFillRemaining(child: ErrorRetryWidget(message: friendlyError(e))),
    );
  }
}

class _InquiryTile extends StatelessWidget {
  final Chat chat;
  const _InquiryTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    // For business owners, Chat.businessName resolves to the customer's name
    // (ChatModel.fromSupabase uses identity resolution based on ownerId)
    final displayName = chat.businessName ?? 'Customer';
    final lastMessage = chat.lastMessage ?? 'No messages yet';
    final timestamp = chat.lastMessageAt ?? chat.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => context.push('/chat', extra: {
          'chat': chat,
          'otherPartyName': displayName,
        }),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
          backgroundImage: chat.businessLogoUrl != null
              ? NetworkImage(chat.businessLogoUrl!)
              : null,
          child: chat.businessLogoUrl == null
              ? Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : 'C',
                  style: GoogleFonts.outfit(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.darkText,
                ),
              ),
            ),
            Text(
              timeago.format(timestamp),
              style:
                  GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }
}
