import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';
import 'package:ifind/features/needs/domain/entities/need.dart';
import 'package:ifind/features/needs/presentation/providers/need_provider.dart';
import 'package:ifind/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:ifind/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:ifind/features/business/presentation/screens/b2b_matches_screen.dart';
import 'package:ifind/features/settings/presentation/screens/settings_screen.dart';
import 'package:ifind/features/products/presentation/screens/add_product_screen.dart';
import 'package:ifind/features/auth/presentation/screens/analytics_screen.dart';
import 'package:ifind/features/reviews/presentation/screens/reviews_screen.dart';

// ---------- Provider for Dashboard Stats ----------
final dashboardStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, businessId) async {
  final supabase = ref.watch(supabaseClientProvider);

  // Each query is wrapped independently — a missing table or RLS block
  // returns 0 instead of crashing the whole provider.
  int views = 0, inquiries = 0, matches = 0;

  try {
    final r = await supabase
        .from('interactions')
        .select('id')
        .eq('business_id', businessId)
        .eq('interaction_type', 'profile_view');
    views = (r as List).length;
  } catch (_) {}

  try {
    final r = await supabase
        .from('interactions')
        .select('id')
        .eq('business_id', businessId)
        .eq('interaction_type', 'inquiry_sent');
    inquiries = (r as List).length;
  } catch (_) {}

  try {
    final r = await supabase
        .from('b2b_matches')
        .select('id')
        .or('business_a_id.eq.$businessId,business_b_id.eq.$businessId');
    matches = (r as List).length;
  } catch (_) {}

  return {'views': views, 'inquiries': inquiries, 'matches': matches};
});

// ---------- The Screen ----------
class LeadsDashboardScreen extends ConsumerStatefulWidget {
  const LeadsDashboardScreen({super.key});

  @override
  ConsumerState<LeadsDashboardScreen> createState() => _LeadsDashboardScreenState();
}

class _LeadsDashboardScreenState extends ConsumerState<LeadsDashboardScreen> {
  // Dark green theme color
  static const darkGreen = Color(0xFF0A5C36);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final myBusinessesAsync = ref.watch(myBusinessesProvider(user?.id ?? ''));
    final business = myBusinessesAsync.value?.firstOrNull;
    final businessId = business?.id;
    final leadsAsync = business == null
        ? const AsyncValue<List<Need>>.data([])
        : ref.watch(businessLeadsProvider(business));
    final statsAsync = businessId != null
        ? ref.watch(dashboardStatsProvider(businessId))
        : const AsyncValue<Map<String, int>>.data({});
    final chatsAsync = businessId != null
        ? ref.watch(businessChatsProvider(businessId))
        : const AsyncValue<List>.data([]);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, business, user?.fullName),
      body: Stack(
        children: [
          // ---------- Light background imagery (subtle shapes) ----------
          Positioned.fill(child: Container(color: Colors.white)),
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: darkGreen.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: darkGreen.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.6,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.withValues(alpha: 0.02),
              ),
            ),
          ),
          // Main content
          RefreshIndicator(
            backgroundColor: Colors.white,
            color: darkGreen,
            onRefresh: () async {
              ref.invalidate(myBusinessesProvider(user?.id ?? ''));
              if (business != null) {
                ref.invalidate(businessLeadsProvider(business));
                ref.invalidate(dashboardStatsProvider(businessId!));
              }
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (business != null) ...[
                          Text(
                            'Welcome back, ${user?.fullName?.split(' ').first ?? 'Owner'}! 👋',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            'Here\'s what\'s happening with ${business.name}',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
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
                      message: 'Create a business profile to receive matching customer inquiries.',
                      icon: Icons.business_center_outlined,
                    ),
                  )
                else ...[
                  // Stats Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildStatsSection(context, ref, statsAsync),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  // Quick Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildQuickActions(context, business),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  // Contacts section (people/businesses that have messaged this business)
                  chatsAsync.when(
                    data: (chats) {
                      if (chats.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contacts',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...chats.map((chat) => _ContactTile(chat: chat)),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                    error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),
                  // Leads List Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Inquiries',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            'View all',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: darkGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  leadsAsync.when(
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                    color: Colors.redAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                ),
                                onDismissed: (_) {
                                  ref.read(needsRepositoryProvider).deleteNeed(need.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lead "${need.title}" dismissed')),
                                  );
                                },
                                child: _LeadCard(
                                  need: need,
                                  business: business,
                                ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1),
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
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Dark Green App Bar (Centered Title, No Overflow) ----------
  PreferredSizeWidget _buildAppBar(BuildContext context, Business? business, String? userName) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(84),
      child: SafeArea(
        child: SizedBox(
          height: 84,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: darkGreen,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Centered Title Column
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Dashboard',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      business?.name ?? 'My Business',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                // Notification Badge - Positioned to the right
                Positioned(
                  right: 0,
                  child: business != null
                      ? NotificationBadge(
                          businessId: business.id,
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => NotificationsScreen(businessId: business.id)),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Stats Section (white cards with dark green accents) ----
  Widget _buildStatsSection(BuildContext context, WidgetRef ref, AsyncValue<Map<String, int>> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        final statItems = [
          {
            'label': 'Profile Views',
            'value': stats['views'] ?? 0,
            'icon': Icons.visibility_rounded,
          },
          {
            'label': 'Inquiries',
            'value': stats['inquiries'] ?? 0,
            'icon': Icons.chat_bubble_outline_rounded,
          },
          {
            'label': 'B2B Matches',
            'value': stats['matches'] ?? 0,
            'icon': Icons.handshake_rounded,
          },
        ];

        return Row(
          children: statItems.map((item) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: darkGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: darkGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item['value'].toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    Text(
                      item['label'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400]),
            const SizedBox(width: 8),
            Text('Could not load stats', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // ---- Quick Actions - some dark green, some white ----
  Widget _buildQuickActions(BuildContext context, Business business) {
    final actions = [
      {'label': 'B2B Matches', 'icon': Icons.handshake_rounded, 'green': true},
      {'label': 'Analytics', 'icon': Icons.analytics_outlined, 'green': true},
      {'label': 'Add Product', 'icon': Icons.add_box_outlined, 'green': true},
      {'label': 'Reviews', 'icon': Icons.star_outline, 'green': true},
      {'label': 'Settings', 'icon': Icons.settings_outlined, 'green': true},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.map((action) {
            final isGreen = action['green'] as bool;
            return GestureDetector(
              onTap: () {
                final label = action['label'] as String;
                switch (label) {
                  case 'B2B Matches':
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const B2bMatchesScreen()));
                    break;
                  case 'Add Product':
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(businessId: business.id)));
                    break;
                  case 'Settings':
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    break;
                  case 'Analytics':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnalyticsScreen(businessId: business.id),
                      ),
                    );
                    break;
                  case 'Reviews':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewsScreen(businessId: business.id),
                      ),
                    );
                    break;
                  default:
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${action['label']} coming soon!')),
                    );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isGreen ? darkGreen : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isGreen ? null : Border.all(color: Colors.grey.shade200, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      action['icon'] as IconData,
                      size: 22,
                      color: isGreen ? Colors.white : darkGreen,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      action['label'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isGreen ? Colors.white : AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------- Lead Card (white, dark green button) ----------
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
    const darkGreen = Color(0xFF0A5C36);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: darkGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  need.category.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: darkGreen,
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
          const SizedBox(height: 8),
          Text(
            need.title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          customerProfileAsync.when(
            data: (customer) => Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, size: 14, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Text(
                  'Posted by ${customer.fullName}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (need.description != null && need.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              need.description!,
              style: GoogleFonts.outfit(
                color: Colors.black87,
                height: 1.4,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: darkGreen,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final customer = customerProfileAsync.value;
                  if (customer == null) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Customer profile is still loading.')),
                    );
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
                    messenger.showSnackBar(
                      SnackBar(content: Text('Could not open chat: $e')),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Message Customer',
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
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact tile — one chat conversation shown in the Contacts section
// ─────────────────────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final Chat chat;
  const _ContactTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final name = chat.isB2B
        ? (chat.businessName ?? 'Business')
        : (chat.customerName ?? 'Customer');
    final subtitle = chat.lastMessage?.isNotEmpty == true
        ? chat.lastMessage!
        : 'No messages yet';
    final timeLabel = chat.lastMessageAt != null
        ? timeago.format(chat.lastMessageAt!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF0A5C36).withValues(alpha: 0.12),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0A5C36),
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (timeLabel.isNotEmpty)
              Text(
                timeLabel,
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[400]),
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0A5C36),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Message',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(chat: chat, otherPartyName: name),
          ),
        ),
      ),
    );
  }
}