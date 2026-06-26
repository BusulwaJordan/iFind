import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:ifind/core/tutorial/app_tutorial.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/core/widgets/owner_avatar.dart';
import 'package:ifind/features/notifications/presentation/widgets/notification_badge.dart';

// ── Hero gradient colours ─────────────────────────────────────────────────────
const _kGradTop    = Color(0xFF003D2B);
const _kGradMid    = Color(0xFF006241);
const _kGradBottom = Color(0xFF0B7A5A);

class HomeScreen extends ConsumerStatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  User get user => widget.user;

  // Used to key child animations so they replay on pull-to-refresh
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFirstVisitTutorial();
    });
  }

  Future<void> _showFirstVisitTutorial() async {
    if (!mounted) return;
    final tutorial = ref.read(tutorialProvider);
    if (!tutorial.shouldShow(AppTutorialService.customerHomeKey)) return;
    await showAppTutorial(
      context: context,
      ref: ref,
      storageKey: AppTutorialService.customerHomeKey,
      steps: const [
        TutorialStep(
          icon: Icons.campaign_rounded,
          title: 'Post a need',
          description:
              'Tell nearby businesses what you are looking for. iFind uses the details to help the right shops understand and respond to your request.',
          action: 'Tap Post a Need when you want sellers to come to you.',
        ),
        TutorialStep(
          icon: Icons.category_rounded,
          title: 'Browse by category',
          description:
              'Popular Categories takes you straight to food, fashion, electronics, home, health, and other local business groups.',
          action: 'Tap any category card to open matching businesses.',
        ),
        TutorialStep(
          icon: Icons.search_rounded,
          title: 'Discover nearby shops',
          description:
              'Use Discover to explore all businesses, compare ratings, and open profiles with contact details, products, reviews, and directions.',
          action: 'Tap Discover when you want to search manually.',
        ),
        TutorialStep(
          icon: Icons.add_business_rounded,
          title: 'Create a shop when ready',
          description:
              'If you own a business, Create Shop guides you through adding your location, contacts, images, products, and management tools.',
          action: 'You can skip this now and return from Quick Actions later.',
        ),
      ],
    );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(featuredBusinessesProvider);
    ref.invalidate(nearbyBusinessesProvider);
    setState(() => _refreshKey++);
    await ref.read(featuredBusinessesProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              // ── Hero ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroSection(
                  key: ValueKey(_refreshKey),
                  user: user,
                ),
              ),

              // ── White content area ─────────────────────────────────────
              SliverToBoxAdapter(
                child: _ContentArea(
                  key: ValueKey('content_$_refreshKey'),
                  user: user,
                  onPostNeed: () => context.push('/post-need'),
                ),
              ),

              // ── Bottom clearance (avoid nav bar overlap) ───────────────
              SliverToBoxAdapter(
                child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 96),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends ConsumerWidget {
  final User user;
  const _HeroSection({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = user.fullName.split(' ').first;
    final role = user.role == UserRole.businessOwner
        ? 'Business Owner'
        : 'Customer';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kGradTop, _kGradMid, _kGradBottom],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative floating circles ───────────────────────────
            ..._decorations(),

            // ── Content ───────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top nav row
                  _TopNav(
                    firstName: firstName,
                    role: role,
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 28),

                  // Greeting
                  _GreetingBlock(firstName: firstName)
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 500.ms)
                      .slideY(begin: 0.25, curve: Curves.easeOutCubic),

                  const SizedBox(height: 28),

                  // Post a Need CTA card
                  const _PostNeedCard()
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(
                        begin: 0.2,
                        delay: 300.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _decorations() {
    const circles = [
      (x: -0.15, y: -0.05, s: 180.0, o: 0.06),
      (x: 0.80,  y: -0.02, s: 140.0, o: 0.05),
      (x: 0.70,  y: 0.50,  s: 200.0, o: 0.04),
      (x: -0.10, y: 0.55,  s: 160.0, o: 0.05),
      (x: 0.40,  y: 0.10,  s: 80.0,  o: 0.04),
    ];
    return circles.map((c) {
      return Positioned(
        left: c.x * 400,
        top: c.y * 400,
        child: Container(
          width: c.s,
          height: c.s,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: c.o),
            shape: BoxShape.circle,
          ),
        ),
      );
    }).toList();
  }
}

// ── Top navigation row ────────────────────────────────────────────────────────

class _TopNav extends ConsumerWidget {
  final String firstName;
  final String role;
  const _TopNav({required this.firstName, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
      child: Row(
        children: [
          // iFind wordmark
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.search_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 9),
              Text(
                'iFind',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          )
              .animate()
              .scale(
                  delay: 50.ms,
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0.7, 0.7)),

          const Spacer(),

          // Notifications
          NotificationBadge(
            child: IconButton(
              onPressed: () => context.push('/notifications'),
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 22),
            ),
          ).animate().fadeIn(delay: 80.ms).slideX(begin: 0.2),

          // Settings
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: Icon(Icons.settings_outlined,
                color: Colors.white.withValues(alpha: 0.8), size: 22),
          ).animate().fadeIn(delay: 110.ms).slideX(begin: 0.2),

          // Profile chip
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 7),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        firstName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        role,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 9.5,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 140.ms).slideX(begin: 0.2),
        ],
      ),
    );
  }
}

// ── Greeting ──────────────────────────────────────────────────────────────────

class _GreetingBlock extends StatelessWidget {
  final String firstName;
  const _GreetingBlock({required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: '$firstName ',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const TextSpan(
                text: '👋',
                style: TextStyle(fontSize: 30),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Text(
            'Find trusted businesses, products\nand services near you.',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Post a Need card ──────────────────────────────────────────────────────────

class _PostNeedCard extends StatelessWidget {
  const _PostNeedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'POST A NEED',
                style: GoogleFonts.outfit(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Need something?\nPost it here.',
            style: GoogleFonts.outfit(
              color: AppColors.deepGreen,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell nearby shops what you want and let them message you.',
            style: GoogleFonts.outfit(
                color: AppColors.lightText, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.deepGreen],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => context.push('/post-need'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Post a Need Now',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800, fontSize: 14),
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
// WHITE CONTENT AREA
// ─────────────────────────────────────────────────────────────────────────────

class _ContentArea extends ConsumerWidget {
  final User user;
  final VoidCallback onPostNeed;
  const _ContentArea(
      {super.key, required this.user, required this.onPostNeed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Getting Started
          _buildGettingStarted(context)
              .animate()
              .fadeIn(delay: 480.ms, duration: 500.ms)
              .slideY(begin: 0.12),
          const SizedBox(height: 32),

          // Popular Categories
          _buildCategoriesSection(context)
              .animate()
              .fadeIn(delay: 600.ms, duration: 500.ms)
              .slideY(begin: 0.12),
          const SizedBox(height: 32),

          // Quick Actions
          _buildQuickActions(context)
              .animate()
              .fadeIn(delay: 720.ms, duration: 500.ms)
              .slideY(begin: 0.12),
          const SizedBox(height: 32),

          // Featured Businesses
          _buildFeaturedSection(context, ref)
              .animate()
              .fadeIn(delay: 840.ms, duration: 500.ms)
              .slideY(begin: 0.12),
          const SizedBox(height: 32),

          // Nearby Top Rated
          _buildNearbySection(context, ref)
              .animate()
              .fadeIn(delay: 960.ms, duration: 500.ms)
              .slideY(begin: 0.12),
        ],
      ),
    );
  }

  // ── Getting Started ─────────────────────────────────────────────────────

  Widget _buildGettingStarted(BuildContext context) {
    final steps = [
      {
        'title': 'Post a Need',
        'desc': 'Tell us what you need and let shops find you.',
        'icon': Icons.edit_note_rounded,
        'color': Colors.blue,
        'onTap': () => context.push('/post-need'),
      },
      {
        'title': 'Explore Shops',
        'desc': 'Discover the best local businesses nearby.',
        'icon': Icons.explore_rounded,
        'color': Colors.orange,
        'onTap': () => context.go('/discover'),
      },
      {
        'title': 'Launch Shop',
        'desc': 'Start your own digital shop and grow.',
        'icon': Icons.rocket_launch_rounded,
        'color': Colors.purple,
        'onTap': () => context.push('/create-business'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const _SectionHeader(title: 'Getting Started'),
              const Spacer(),
              Text(
                'Step 1 of 3',
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.lightText,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 132,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final color = step['color'] as Color;
              return GestureDetector(
                onTap: step['onTap'] as VoidCallback,
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: color.withValues(alpha: 0.12), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(step['icon'] as IconData,
                          color: color, size: 28),
                      const Spacer(),
                      Text(step['title'] as String,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(step['desc'] as String,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.lightText),
                          maxLines: 2),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: (index * 80 + 500).ms, duration: 400.ms)
                  .scale(
                      begin: const Offset(0.92, 0.92),
                      delay: (index * 80 + 500).ms);
            },
          ),
        ),
      ],
    );
  }

  // ── Categories ──────────────────────────────────────────────────────────

  Widget _buildCategoriesSection(BuildContext context) {
    final categories = [
      {'name': 'Food', 'image': 'assets/images/Screenshot 2026-02-11 112931.png', 'icon': Icons.restaurant_rounded, 'cat': BusinessCategory.food},
      {'name': 'Fashion', 'image': 'assets/images/Color Gradient T-shirts Display.png', 'icon': Icons.checkroom_rounded, 'cat': BusinessCategory.fashion},
      {'name': 'Electronics', 'image': 'assets/images/Contemporary VR Headsets Display.png', 'icon': Icons.devices_rounded, 'cat': BusinessCategory.electronics},
      {'name': 'Home', 'image': 'assets/images/Modern Workspace Setup.png', 'icon': Icons.home_rounded, 'cat': BusinessCategory.home},
      {'name': 'Beauty', 'image': null, 'icon': Icons.spa_rounded, 'cat': BusinessCategory.beauty},
      {'name': 'Services', 'image': null, 'icon': Icons.handyman_rounded, 'cat': BusinessCategory.service},
      {'name': 'Automotive', 'image': null, 'icon': Icons.directions_car_rounded, 'cat': BusinessCategory.automotive},
      {'name': 'Health', 'image': null, 'icon': Icons.local_hospital_rounded, 'cat': BusinessCategory.health},
      {'name': 'Sports', 'image': 'assets/images/Screenshot 2026-02-11 112211.png', 'icon': Icons.sports_basketball_rounded, 'cat': BusinessCategory.sports},
      {'name': 'Kids', 'image': 'assets/images/Screenshot 2026-02-11 113140.png', 'icon': Icons.child_care_rounded, 'cat': BusinessCategory.kids},
      {'name': 'Education', 'image': null, 'icon': Icons.school_rounded, 'cat': BusinessCategory.education},
      {'name': 'Events', 'image': 'assets/images/Screenshot 2026-02-11 113011.png', 'icon': Icons.event_rounded, 'cat': BusinessCategory.entertainment},
      {'name': 'Travel', 'image': null, 'icon': Icons.flight_takeoff_rounded, 'cat': BusinessCategory.travel},
      {'name': 'Properties', 'image': null, 'icon': Icons.apartment_rounded, 'cat': BusinessCategory.realEstate},
      {'name': 'Pets', 'image': 'assets/images/Screenshot 2026-02-11 112656.png', 'icon': Icons.pets_rounded, 'cat': BusinessCategory.pets},
      {'name': 'Finance', 'image': null, 'icon': Icons.account_balance_wallet_rounded, 'cat': BusinessCategory.finance},
    ];

    final row1 = categories.sublist(0, (categories.length / 2).ceil());
    final row2 = categories.sublist((categories.length / 2).ceil());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader(title: 'Popular Categories'),
              Text('Swipe for more',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: row1
                .map((cat) => _ThreeDCategoryCard(
                      name: cat['name'] as String,
                      image: cat['image'] as String?,
                      icon: cat['icon'] as IconData,
                      category: cat['cat'] as BusinessCategory,
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: row2
                .map((cat) => _ThreeDCategoryCard(
                      name: cat['name'] as String,
                      image: cat['image'] as String?,
                      icon: cat['icon'] as IconData,
                      category: cat['cat'] as BusinessCategory,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ── Quick Actions ───────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  title: 'Discover',
                  subtitle: 'Explore local shops',
                  icon: Icons.search_rounded,
                  color: AppColors.primaryGreen,
                  onTap: () => context.go('/discover'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  title: 'For You',
                  subtitle: 'AI recommendations',
                  icon: Icons.auto_awesome_rounded,
                  color: Colors.deepPurple,
                  onTap: () => context.go('/for-you'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  title: 'Favourites',
                  subtitle: 'Saved businesses',
                  icon: Icons.bookmark_rounded,
                  color: Colors.amber.shade700,
                  onTap: () => context.push('/favourites'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  title: 'Create Shop',
                  subtitle: 'Reach more people',
                  icon: Icons.add_business_rounded,
                  color: AppColors.deepGreen,
                  onTap: () => context.push('/create-business'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Featured Businesses ─────────────────────────────────────────────────

  Widget _buildFeaturedSection(BuildContext context, WidgetRef ref) {
    final businessesAsync = ref.watch(featuredBusinessesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _SectionHeader(title: 'Featured Businesses'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: businessesAsync.when(
            data: (businesses) {
              if (businesses.isEmpty) {
                return const Center(
                    child: Text('No featured businesses yet'));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: businesses.length,
                itemBuilder: (context, index) {
                  return _FeaturedBusinessCard(business: businesses[index])
                      .animate()
                      .fadeIn(delay: (index * 100).ms)
                      .scale(begin: const Offset(0.9, 0.9));
                },
              );
            },
            loading: () => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (_, __) => Container(
                width: 280,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            error: (e, _) =>
                ErrorRetryWidget(message: friendlyError(e), slim: true),
          ),
        ),
      ],
    );
  }

  // ── Nearby ──────────────────────────────────────────────────────────────

  Widget _buildNearbySection(BuildContext context, WidgetRef ref) {
    final nearbyAsync = ref.watch(nearbyBusinessesProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Nearby Top Rated'),
          const SizedBox(height: 16),
          nearbyAsync.when(
            data: (businesses) {
              if (businesses.isEmpty) return const _NearbyPlaceholder();
              return Column(
                children: businesses.asMap().entries.map((e) {
                  return _NearbyBusinessCard(business: e.value)
                      .animate()
                      .fadeIn(delay: (e.key * 80).ms, duration: 400.ms)
                      .slideX(begin: 0.1);
                }).toList(),
              );
            },
            loading: () =>
                const Center(child: IFindLoaderInline(size: 60)),
            error: (e, _) =>
                ErrorRetryWidget(message: friendlyError(e), slim: true),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.deepGreen,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURED BUSINESS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedBusinessCard extends ConsumerWidget {
  final Business business;
  const _FeaturedBusinessCard({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveBusiness =
        ref.watch(businessStreamProvider(business.id)).valueOrNull ??
            business;

    return GestureDetector(
      onTap: () =>
          context.push('/business-details', extra: liveBusiness),
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: NetworkImage(
              liveBusiness.coverImageUrl ??
                  'https://via.placeholder.com/300',
            ),
            fit: BoxFit.cover,
            onError: (_, __) {},
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8)
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveBusiness.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${liveBusiness.rating.toStringAsFixed(1)} (${liveBusiness.reviewCount} reviews)',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OwnerAvatar(ownerId: liveBusiness.ownerId, radius: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-D CATEGORY CARD (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _ThreeDCategoryCard extends StatelessWidget {
  final String name;
  final String? image;
  final IconData icon;
  final BusinessCategory category;

  const _ThreeDCategoryCard({
    required this.name,
    required this.image,
    required this.icon,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/discover', extra: category),
      child: Container(
        width: 140,
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          children: [
            Positioned(
              bottom: 12, left: 15, right: 15,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      blurRadius: 25,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40, left: -40,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Hero(
                              tag: 'cat_img_$name',
                              child: Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateX(-0.1)
                                  ..rotateY(0.1),
                                alignment: Alignment.center,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: image == null
                                      ? _CategoryIconPanel(icon: icon)
                                      : Image.asset(
                                          image!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _CategoryIconPanel(icon: icon),
                                        ),
                                ),
                              ),
                            ),
                          )
                              .animate(
                                  onPlay: (c) =>
                                      c.repeat(reverse: true))
                              .moveY(
                                begin: -4,
                                end: 4,
                                duration: 2.seconds,
                                curve: Curves.easeInOut,
                              ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryIconPanel extends StatelessWidget {
  final IconData icon;
  const _CategoryIconPanel({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.lightGreen.withValues(alpha: 0.28),
            AppColors.primaryGreen.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, color: AppColors.deepGreen, size: 42),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.lightText)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEARBY BUSINESS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _NearbyBusinessCard extends ConsumerWidget {
  final Business business;
  const _NearbyBusinessCard({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamed =
        ref.watch(businessStreamProvider(business.id)).valueOrNull;
    final live = streamed == null
        ? business
        : streamed.copyWith(
            distance: streamed.distance ?? business.distance);

    return GestureDetector(
      onTap: () => context.push('/business-details', extra: live),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      image: live.logoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(live.logoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: live.logoUrl == null
                        ? Center(
                            child: Text(
                              live.name.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: -6,
                    right: -6,
                    child: OwnerAvatar(ownerId: live.ownerId, radius: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(live.name,
                      style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${live.rating.toStringAsFixed(1)} (${live.reviewCount})',
                        style: const TextStyle(
                            color: AppColors.lightText, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.circle,
                          size: 4, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        live.category.name.toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _NearbyPlaceholder extends StatelessWidget {
  const _NearbyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.primaryGreen, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Finding nearby...',
                    style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                    'Scan for shops in your local arcade or street.',
                    style: TextStyle(
                        color: AppColors.lightText, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

