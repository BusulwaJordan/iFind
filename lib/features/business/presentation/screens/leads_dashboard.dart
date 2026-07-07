import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/app_drawer.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/presentation/providers/b2b_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';
import 'package:ifind/features/needs/domain/entities/need.dart';
import 'package:ifind/features/needs/presentation/providers/need_provider.dart';
import 'package:ifind/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:ifind/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:ifind/features/notifications/utils/notification_preview_formatter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ifind/features/business/presentation/screens/b2b_matches_screen.dart';
import 'package:ifind/features/settings/presentation/screens/settings_screen.dart';
import 'package:ifind/features/products/presentation/screens/add_product_screen.dart';
import 'package:ifind/features/auth/presentation/screens/analytics_screen.dart';
import 'package:ifind/features/reviews/presentation/screens/reviews_screen.dart';

const _kGradTop = Color(0xFF003D2B);
const _kGradMid = Color(0xFF006241);
const _kGradBot = Color(0xFF0B7A5A);

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────
class LeadsDashboardScreen extends ConsumerStatefulWidget {
  const LeadsDashboardScreen({super.key});

  @override
  ConsumerState<LeadsDashboardScreen> createState() =>
      _LeadsDashboardScreenState();
}

class _LeadsDashboardScreenState
    extends ConsumerState<LeadsDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final myBusinessesAsync =
        ref.watch(myBusinessesStreamProvider(user?.id ?? ''));
    final business = myBusinessesAsync.valueOrNull?.firstOrNull;
    final businessId = business?.id;

    final leadsAsync = business == null
        ? const AsyncValue<List<Need>>.data([])
        : ref.watch(businessLeadsProvider(business));
    final statsAsync = businessId != null
        ? ref.watch(analyticsDataProvider(businessId))
        : const AsyncValue<Map<String, int>>.data({});
    final chatsAsync = businessId != null
        ? ref.watch(unansweredContactsProvider(businessId))
        : const AsyncValue<List>.data([]);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _HeroHeader(
            scaffoldKey: _scaffoldKey,
            user: user,
            business: business,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              displacement: 40,
              onRefresh: () async {
                ref.invalidate(myBusinessesStreamProvider(user?.id ?? ''));
                if (business != null && businessId != null) {
                  ref.invalidate(businessLeadsProvider(business));
                  ref.invalidate(analyticsDataProvider(businessId));
                  ref.invalidate(b2bPartnerCandidatesProvider(businessId));
                  ref.invalidate(unansweredContactsProvider(businessId));
                }
              },
              child: CustomScrollView(
                slivers: [
                  // ── Loading / empty state ──────────────────────────────────
            if (myBusinessesAsync.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (business == null)
              SliverFillRemaining(
                child: _NoBusinessPlaceholder(
                  onCreateShop: () => context.go('/setup-shop'),
                ),
              )
            else ...[
              // ── Stats grid ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _StatsSection(
                    statsAsync: statsAsync,
                    business: business,
                  ),
                ),
              ),

              // ── Quick Actions + Grow card ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _ActionsRow(business: business),
                ),
              ),

              // ── Recent Contacts ────────────────────────────────────────────
              chatsAsync.when(
                data: (rawChats) {
                  final chats = rawChats.cast<Chat>();
                  if (chats.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _ContactsSection(chats: chats),
                    ),
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // ── Recent Inquiries header ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Inquiries',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        'View all',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Lead cards ─────────────────────────────────────────────────
              leadsAsync.when(
                data: (needs) {
                  if (needs.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: EmptyStateWidget(
                          title: 'All caught up!',
                          message:
                              'New local needs will appear here as customers post them.',
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    Colors.redAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent),
                            ),
                            onDismissed: (_) {
                              ref
                                  .read(needsRepositoryProvider)
                                  .deleteNeed(need.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Lead "${need.title}" dismissed')),
                              );
                            },
                            child: _LeadCard(
                              need: need,
                              business: business,
                            )
                                .animate()
                                .fadeIn(delay: (index * 80).ms)
                                .slideY(begin: 0.06, duration: 350.ms),
                          );
                        },
                        childCount: needs.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('Error: $e'),
                    ),
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 48)),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Header
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final User? user;
  final Business? business;

  const _HeroHeader({
    required this.scaffoldKey,
    required this.user,
    required this.business,
  });

  @override
  Widget build(BuildContext context) {
    final firstName =
        user?.fullName.split(' ').first ?? 'Owner';
    final avatarUrl = user?.avatarUrl;
    final initial = (user?.fullName ?? 'O')[0].toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kGradTop, _kGradMid, _kGradBot],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: menu | brand | notification | avatar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded,
                        color: Colors.white, size: 26),
                    onPressed: () =>
                        scaffoldKey.currentState?.openDrawer(),
                    padding: EdgeInsets.zero,
                  ),
                  Expanded(
                    child: Text(
                      'iFind',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (business != null)
                    NotificationBadge(
                      businessId: business!.id,
                      child: IconButton(
                        icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 26),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationsScreen(
                                businessId: business!.id),
                          ),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    )
                  else
                    const SizedBox(width: 44),
                  const SizedBox(width: 8),
                  // User avatar
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white54, width: 2),
                        color: Colors.white24,
                        image: avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: avatarUrl == null
                          ? Center(
                              child: Text(
                                initial,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Greeting
              Text(
                'Welcome back, $firstName! 👋',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 4),
              Text(
                "Let's grow your business today.",
                style: GoogleFonts.outfit(
                    color: Colors.white70, fontSize: 14),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              // Business identity card
              if (business != null) ...[
                const SizedBox(height: 18),
                _BusinessCard(business: business!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Business Identity Card (inside header)
// ─────────────────────────────────────────────────────────────────────────────

class _BusinessCard extends StatelessWidget {
  final Business business;
  const _BusinessCard({required this.business});

  @override
  Widget build(BuildContext context) {
    final catLabel = business.category.name[0].toUpperCase() +
        business.category.name.substring(1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white54, width: 1.5),
              image: business.logoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(business.logoUrl!),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: business.logoUrl == null
                ? Center(
                    child: Text(
                      business.name[0].toUpperCase(),
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name,
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  catLabel,
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 12),
                ),
                if (business.address != null &&
                    business.address!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white54, size: 12),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          business.address!,
                          style: GoogleFonts.outfit(
                              color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Colors.white54, size: 20),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05, duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Grid (2 × 2)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsSection extends ConsumerWidget {
  final AsyncValue<Map<String, int>> statsAsync;
  final Business business;

  const _StatsSection(
      {required this.statsAsync, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsReceived =
        ref.watch(businessPostsReceivedProvider(business.id)).valueOrNull ?? 0;
    final contacts =
        ref.watch(businessContactsProvider(business.id)).valueOrNull ?? 0;
    final b2bMatches =
        ref.watch(b2bPartnerCandidatesProvider(business.id)).valueOrNull?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Business Overview',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AnalyticsScreen(businessId: business.id),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'View Analytics',
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.primaryGreen, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (stats) {
            final items = [
              _StatItem(
                icon: Icons.visibility_outlined,
                value: stats['views'] ?? 0,
                label: 'Profile Views',
                accent: const Color(0xFF3B82F6),
              ),
              _StatItem(
                icon: Icons.campaign_outlined,
                value: postsReceived,
                label: 'Customer Inquiries',
                accent: const Color(0xFFF59E0B),
              ),
              _StatItem(
                icon: Icons.person_add_alt_1_outlined,
                value: contacts,
                label: 'Contacts',
                accent: const Color(0xFF8B5CF6),
              ),
              _StatItem(
                icon: Icons.handshake_outlined,
                value: b2bMatches,
                label: 'B2B Matches',
                accent: const Color(0xFF10B981),
              ),
            ];
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: items.asMap().entries.map((entry) {
                return _StatCard(item: entry.value)
                    .animate()
                    .fadeIn(delay: (entry.key * 80).ms)
                    .scale(
                        begin: const Offset(0.92, 0.92),
                        duration: 350.ms,
                        curve: Curves.easeOutBack);
              }).toList(),
            );
          },
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _StatItem {
  final IconData icon;
  final int value;
  final String label;
  final Color accent;
  const _StatItem(
      {required this.icon, required this.value, required this.label, required this.accent});
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon,
                color: item.accent, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value.toString(),
                style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText),
              ),
              Text(
                item.label,
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions + Grow Card (side by side)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionsRow extends StatelessWidget {
  final Business business;
  const _ActionsRow({required this.business});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ActionGrid(business: business),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 130,
              child: _GrowCard(business: business),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final Business business;
  const _ActionGrid({required this.business});

  void _onTap(BuildContext context, String label) {
    switch (label) {
      case 'B2B Matches':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const B2bMatchesScreen()));
      case 'Analytics':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    AnalyticsScreen(businessId: business.id)));
      case 'Add Product':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    AddProductScreen(businessId: business.id)));
      case 'Reviews':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ReviewsScreen(businessId: business.id)));
      case 'Messages':
        context.go('/chats');
      case 'Settings':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()));
      case 'Post a Need':
        // No `extra` — broadcasts to nearby category matches, same as the
        // customer-facing entry points (unlike the targeted one on a
        // specific business's profile page).
        context.push('/post-need');
    }
  }

  @override
  Widget build(BuildContext context) {
    const actions = [
      (label: 'B2B Matches', icon: Icons.handshake_rounded,    color: Color(0xFF6366F1)),
      (label: 'Analytics',   icon: Icons.bar_chart_rounded,    color: Color(0xFFF59E0B)),
      (label: 'Post a Need', icon: Icons.campaign_rounded,     color: Color(0xFF06B6D4)),
      (label: 'Add Product', icon: Icons.add_box_rounded,      color: Color(0xFF10B981)),
      (label: 'Reviews',     icon: Icons.star_rounded,         color: Color(0xFFEC4899)),
      (label: 'Messages',    icon: Icons.chat_bubble_rounded,  color: Color(0xFF3B82F6)),
      (label: 'Settings',    icon: Icons.settings_rounded,     color: Color(0xFF8B5CF6)),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.88,
      children: actions.indexed.map((entry) {
        final (i, action) = entry;
        return GestureDetector(
          onTap: () => _onTap(context, action.label),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(action.icon,
                      color: action.color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  action.label,
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: (i * 50).ms)
              .scale(
                  begin: const Offset(0.88, 0.88),
                  duration: 300.ms,
                  curve: Curves.easeOutBack),
        );
      }).toList(),
    );
  }
}

class _GrowCard extends StatelessWidget {
  final Business business;
  const _GrowCard({required this.business});

  int _score() {
    int s = 20; // name always present
    if (business.description.length >= 20) s += 20;
    if (business.logoUrl != null) s += 20;
    if (business.coverImageUrl != null) s += 20;
    if (business.phone != null || business.email != null) s += 20;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final score = _score();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGradTop, _kGradMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grow Your Business',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete your profile, add more products and get more visibility.',
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 10, height: 1.4),
          ),
          const SizedBox(height: 16),
          // Circular progress indicator
          Center(
            child: SizedBox(
              width: 68,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 5,
                  ),
                  Text(
                    '$score%',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // "Complete Profile" button
          GestureDetector(
            onTap: () => context.push('/shop-profile'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Complete',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms)
        .slideX(begin: 0.1, duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Contacts Section
// ─────────────────────────────────────────────────────────────────────────────

class _ContactsSection extends StatelessWidget {
  final List<Chat> chats;
  const _ContactsSection({required this.chats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Contacts',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText),
            ),
            GestureDetector(
              onTap: () => context.go('/chats'),
              child: Text(
                'View all',
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...chats.take(3).indexed.map((entry) {
          final (i, chat) = entry;
          return _ContactTile(chat: chat, index: i)
              .animate()
              .fadeIn(delay: (i * 80).ms)
              .slideX(begin: 0.05, duration: 350.ms);
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No Business Placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _NoBusinessPlaceholder extends StatelessWidget {
  final VoidCallback onCreateShop;
  const _NoBusinessPlaceholder({required this.onCreateShop});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_rounded, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'No shop set up yet',
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your shop profile to start receiving customers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreateShop,
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Create Shop'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lead Card
// ─────────────────────────────────────────────────────────────────────────────

class _LeadCard extends ConsumerWidget {
  final Need need;
  final Business business;

  const _LeadCard({required this.need, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerProfileAsync =
        ref.watch(userProfileProvider(need.userId));
    // A need's poster may be a business owner (posting from another
    // business's profile page) rather than a plain customer — show their
    // business's name in that case instead of the need's category, and
    // fall back to their username otherwise.
    final posterBusinesses =
        ref.watch(myBusinessesProvider(need.userId)).valueOrNull ?? [];
    final posterIdentity = posterBusinesses.isNotEmpty
        ? posterBusinesses.first.name
        : (customerProfileAsync.valueOrNull?.fullName ?? need.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
        ),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  posterIdentity,
                  style: GoogleFonts.outfit(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    timeago.format(need.createdAt),
                    style:
                        GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.more_vert_rounded,
                      color: Colors.grey[400], size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            need.title,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          customerProfileAsync.when(
            data: (customer) => Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor:
                      AppColors.primaryGreen.withValues(alpha: 0.1),
                  backgroundImage: customer.avatarUrl != null &&
                          customer.avatarUrl!.isNotEmpty
                      ? NetworkImage(customer.avatarUrl!)
                      : null,
                  child: customer.avatarUrl != null &&
                          customer.avatarUrl!.isNotEmpty
                      ? null
                      : const Icon(Icons.person,
                          size: 13, color: AppColors.primaryGreen),
                ),
                const SizedBox(width: 6),
                Text(
                  'Posted by ${customer.fullName}',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (need.description != null &&
              need.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              need.description!,
              style: GoogleFonts.outfit(
                  color: Colors.black87, height: 1.4, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          // Message Customer button
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryGreen, AppColors.deepGreen],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  // The need's content is already sent as the opening
                  // message when the customer submits a need targeted at
                  // this business (see PostNeedController.submitNeed) — it
                  // has to happen there, not here, since messages.sender_id
                  // must equal auth.uid() and the business owner can't send
                  // "as" the customer.
                  final chat = await ref
                      .read(chatRemoteDataSourceProvider)
                      .getOrCreateChat(
                        customerId: need.userId,
                        businessId: business.id,
                      );
                  ref.invalidate(businessLeadsProvider(business));
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          chat: chat,
                          otherPartyName: posterIdentity,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  messenger.showSnackBar(
                      SnackBar(content: Text('Could not open chat: $e')));
                }
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.white, size: 18),
              label: Text(
                'Message Customer',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact Tile
// ─────────────────────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final Chat chat;
  final int index;
  const _ContactTile({required this.chat, required this.index});

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF10B981),
    ];
    final avatarColor = colors[index % colors.length];
    final name = chat.isB2B
        ? (chat.businessName ?? 'Business')
        : (chat.customerName ?? 'Customer');
    final avatarUrl =
        chat.isB2B ? chat.partnerBusinessLogo : chat.customerAvatarUrl;
    final cleanedLastMessage = chat.lastMessage?.isNotEmpty == true
        ? NotificationPreviewFormatter.cleanBody(chat.lastMessage!)
        : null;
    final lastMsg = cleanedLastMessage == null || cleanedLastMessage.isEmpty
        ? 'Start a conversation'
        : (cleanedLastMessage.length > 40
            ? '${cleanedLastMessage.substring(0, 40)}...'
            : cleanedLastMessage);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final updatedAt = chat.updatedAt;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(chat: chat, otherPartyName: name),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: avatarColor.withValues(alpha: 0.15),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              onBackgroundImageError: avatarUrl != null ? (_, __) {} : null,
              child: avatarUrl != null
                  ? null
                  : Text(
                      initial,
                      style: GoogleFonts.outfit(
                          color: avatarColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
            ),
            const SizedBox(width: 12),
            // Name + message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.darkText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMsg,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time + message button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    timeago.format(updatedAt),
                    style: GoogleFonts.outfit(
                        fontSize: 10, color: Colors.grey[500]),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Message',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
