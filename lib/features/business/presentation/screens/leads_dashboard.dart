import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:ifind/features/needs/domain/entities/need.dart';
import 'package:ifind/features/needs/presentation/providers/need_provider.dart';
import 'package:ifind/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:ifind/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';

class LeadsDashboardScreen extends ConsumerWidget {
  const LeadsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final myBusinessesAsync = ref.watch(myBusinessesProvider(user?.id ?? ''));
    final business = myBusinessesAsync.value?.firstOrNull;
    final businessId = business?.id;
    final leadsAsync = business == null
        ? const AsyncValue<List<Need>>.data([])
        : ref.watch(businessLeadsProvider(business));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: 0.05),
              ),
            ),
          ),

          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myBusinessesProvider(user?.id ?? ''));
              if (business != null) {
                ref.invalidate(businessLeadsProvider(business));
              }
            },
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, businessId),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Market Opportunities',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          'Potential customers looking for your services nearby',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (myBusinessesAsync.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (business == null)
                  const SliverFillRemaining(
                    child: EmptyStateWidget(
                      title: 'No business yet',
                      message:
                          'Create a business profile to receive matching customer inquiries.',
                      icon: Icons.business_center_outlined,
                    ),
                  )
                else
                  leadsAsync.when(
                    data: (needs) {
                      if (needs.isEmpty) {
                        return const SliverFillRemaining(
                          child: EmptyStateWidget(
                            title: 'All caught up!',
                            message:
                                'New local needs will appear here as customers post them.',
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final need = needs[index];
                              return Dismissible(
                                key: Key('lead_${need.id}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent),
                                ),
                                onDismissed: (_) {
                                  ref
                                      .read(needsRepositoryProvider)
                                      .deleteNeed(need.id);
                                  AppToast.show(context, 'Lead "${need.title}" dismissed', type: ToastType.info);
                                },
                                child: _LeadCard(
                                  need: need,
                                  business: business,
                                )
                                    .animate()
                                    .fadeIn(delay: (index * 100).ms)
                                    .slideY(begin: 0.1),
                              );
                            },
                            childCount: needs.length,
                          ),
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator())),
                    error: (e, s) => SliverFillRemaining(
                        child: ErrorRetryWidget(message: friendlyError(e))),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String? businessId) {
    return SliverAppBar(
      expandedHeight: 190,
      pinned: true,
      backgroundColor: AppColors.deepGreen,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
      ),
      actions: [
        if (businessId != null)
          NotificationBadge(
            businessId: businessId,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_rounded,
                    color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        NotificationsScreen(businessId: businessId)),
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.deepGreen, AppColors.primaryGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.trending_up_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leads Dashboard',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Customer needs near your business',
                            style: GoogleFonts.outfit(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadCard extends ConsumerWidget {
  final Need need;
  final Business business;

  const _LeadCard({
    required this.need,
    required this.business,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerProfileAsync = ref.watch(userProfileProvider(need.userId));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category & Time
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    need.category.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  timeago.format(need.createdAt),
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  need.title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                customerProfileAsync.when(
                  data: (customer) => Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person,
                            size: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Posted by ${customer.fullName}',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                if (need.description != null &&
                    need.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    need.description!,
                    style: GoogleFonts.outfit(
                        color: Colors.black87, height: 1.5, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 24),

                // Action
                Material(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () async {
                      final customer = customerProfileAsync.value;
                      if (customer == null) {
                        AppToast.show(context, 'Customer profile is still loading.', type: ToastType.warning);
                        return;
                      }

                      try {
                        final chat = await ref
                            .read(chatRemoteDataSourceProvider)
                            .getOrCreateChat(
                              customerId: need.userId,
                              businessId: business.id,
                            );

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatRoomScreen(
                                chat: chat,
                                otherPartyName: customer.fullName,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppToast.show(context, friendlyError(e), type: ToastType.error);
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Message in iFind',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
