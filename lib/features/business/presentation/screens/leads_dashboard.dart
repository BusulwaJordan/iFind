import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/needs/domain/entities/need.dart';
import 'package:ifind/features/needs/presentation/providers/need_provider.dart';
import 'package:ifind/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:ifind/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class LeadsDashboardScreen extends ConsumerWidget {
  const LeadsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsAsync = ref.watch(nearbyNeedsProvider);
    final user = ref.watch(currentUserProvider);
    final myBusinessesAsync = ref.watch(myBusinessesProvider(user?.id ?? ''));
    final businessId = myBusinessesAsync.value?.firstOrNull?.id;

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
            onRefresh: () async => ref.refresh(nearbyNeedsProvider),
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
                needsAsync.when(
                  data: (needs) {
                    if (needs.isEmpty) {
                      return const SliverFillRemaining(
                        child: EmptyStateWidget(
                          title: 'All caught up!',
                          message: 'New local needs will appear here as customers post them.',
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
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              ),
                              onDismissed: (_) {
                                ref.read(needsRepositoryProvider).deleteNeed(need.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lead "${need.title}" dismissed')),
                                );
                              },
                              child: _LeadCard(need: need)
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
                  loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                  error: (e, s) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
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
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Customer Inquiries',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
            fontSize: 20,
          ),
        ),
        background: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
      ),
      actions: [
        if (businessId != null)
          NotificationBadge(
            businessId: businessId,
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.darkText),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationsScreen(businessId: businessId)),
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _LeadCard extends ConsumerWidget {
  final Need need;
  const _LeadCard({required this.need});

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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        child: const Icon(Icons.person, size: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Posted by ${customer.fullName}',
                        style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                if (need.description != null && need.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    need.description!,
                    style: GoogleFonts.outfit(color: Colors.black87, height: 1.5, fontSize: 14),
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
                      if (customer != null && customer.phone != null) {
                        final cleanPhone = customer.phone!.replaceAll(RegExp(r'[^0-9]'), '');
                        final whatsappPhone = cleanPhone.startsWith('256') ? cleanPhone : '256$cleanPhone';
                        final uri = Uri.parse('https://wa.me/$whatsappPhone?text=Hi ${customer.fullName.split(" ").first}, I saw your request for "${need.title}" on iFind.');
                        
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Connect on WhatsApp',
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
