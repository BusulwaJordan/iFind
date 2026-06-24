import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/core/tutorial/app_tutorial.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  User get user => widget.user;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featuredBusinessesProvider);
          ref.invalidate(nearbyBusinessesProvider);
          return await ref.read(featuredBusinessesProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, ref),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBroadcastBanner(context)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2),
                    const SizedBox(height: 32),
                    _buildGettingStarted(context)
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 32),
                    _buildCategoriesSection(context)
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 32),
                    _buildQuickActions(context)
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 32),
                    _buildFeaturedSection(context, ref)
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.1),
                    const SizedBox(height: 32),
                    _buildNearbySection(context, ref)
                        .animate()
                        .fadeIn(delay: 800.ms)
                        .slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.deepGreen,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  user.fullName.split(' ').first,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            NotificationBadge(
              child: IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 24),
              ),
            ),
            IconButton(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined,
                  color: Colors.white70, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'POST A NEED',
                style: GoogleFonts.outfit(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Need something? Post it here.',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell nearby shops what you want and let them message you in iFind.',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, // Full width button
            child: ElevatedButton(
              onPressed: () => context.push('/post-need'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Post a Need Now',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

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
                return const Center(child: Text('No featured businesses yet'));
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
            error: (e, _) => ErrorRetryWidget(message: friendlyError(e), slim: true),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final categories = [
      {
        'name': 'Food',
        'image': 'assets/images/Screenshot 2026-02-11 112931.png',
        'icon': Icons.restaurant_rounded,
        'cat': BusinessCategory.food
      },
      {
        'name': 'Fashion',
        'image': 'assets/images/Color Gradient T-shirts Display.png',
        'icon': Icons.checkroom_rounded,
        'cat': BusinessCategory.fashion
      },
      {
        'name': 'Electronics',
        'image': 'assets/images/Contemporary VR Headsets Display.png',
        'icon': Icons.devices_rounded,
        'cat': BusinessCategory.electronics
      },
      {
        'name': 'Home',
        'image': 'assets/images/Modern Workspace Setup.png',
        'icon': Icons.home_rounded,
        'cat': BusinessCategory.home
      },
      {
        'name': 'Beauty',
        'image': null,
        'icon': Icons.spa_rounded,
        'cat': BusinessCategory.beauty
      },
      {
        'name': 'Services',
        'image': null,
        'icon': Icons.handyman_rounded,
        'cat': BusinessCategory.service
      },
      {
        'name': 'Automotive',
        'image': null,
        'icon': Icons.directions_car_rounded,
        'cat': BusinessCategory.automotive
      },
      {
        'name': 'Health',
        'image': null,
        'icon': Icons.local_hospital_rounded,
        'cat': BusinessCategory.health
      },
      {
        'name': 'Sports',
        'image': 'assets/images/Screenshot 2026-02-11 112211.png',
        'icon': Icons.sports_basketball_rounded,
        'cat': BusinessCategory.sports
      },
      {
        'name': 'Kids',
        'image': 'assets/images/Screenshot 2026-02-11 113140.png',
        'icon': Icons.child_care_rounded,
        'cat': BusinessCategory.kids
      },
      {
        'name': 'Education',
        'image': null,
        'icon': Icons.school_rounded,
        'cat': BusinessCategory.education
      },
      {
        'name': 'Events',
        'image': 'assets/images/Screenshot 2026-02-11 113011.png',
        'icon': Icons.event_rounded,
        'cat': BusinessCategory.entertainment
      },
      {
        'name': 'Travel',
        'image': null,
        'icon': Icons.flight_takeoff_rounded,
        'cat': BusinessCategory.travel
      },
      {
        'name': 'Properties',
        'image': null,
        'icon': Icons.apartment_rounded,
        'cat': BusinessCategory.realEstate
      },
      {
        'name': 'Pets',
        'image': 'assets/images/Screenshot 2026-02-11 112656.png',
        'icon': Icons.pets_rounded,
        'cat': BusinessCategory.pets
      },
      {
        'name': 'Finance',
        'image': null,
        'icon': Icons.account_balance_wallet_rounded,
        'cat': BusinessCategory.finance
      },
    ];

    // Split into 2 rows
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
              Text(
                'Swipe for more',
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold),
              ),
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
                  onTap: () => context.push('/ai-search'),
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
              Text('Step 1 of 3',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.lightText,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (step['color'] as Color).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: (step['color'] as Color).withValues(alpha: 0.1)),
                ),
                child: InkWell(
                  onTap: step['onTap'] as VoidCallback,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(step['icon'] as IconData,
                          color: step['color'] as Color, size: 28),
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNearbySection(BuildContext context, WidgetRef ref) {
    final nearbyBusinessesAsync = ref.watch(nearbyBusinessesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Nearby Top Rated'),
          const SizedBox(height: 16),
          nearbyBusinessesAsync.when(
            data: (businesses) {
              if (businesses.isEmpty) {
                return const _NearbyPlaceholder();
              }
              return Column(
                children: businesses.map((business) {
                  return _NearbyBusinessCard(business: business)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.1);
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorRetryWidget(message: friendlyError(e), slim: true),
          ),
        ],
      ),
    );
  }
}

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

class _FeaturedBusinessCard extends ConsumerWidget {
  final Business business;
  const _FeaturedBusinessCard({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveBusiness =
        ref.watch(businessStreamProvider(business.id)).valueOrNull ?? business;

    return GestureDetector(
      onTap: () => context.push('/business-details', extra: liveBusiness),
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: NetworkImage(
              liveBusiness.coverImageUrl ?? 'https://via.placeholder.com/300',
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
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
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
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            // Outer Depth Shadow
            Positioned(
              bottom: 12,
              left: 15,
              right: 15,
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

            // Main Card Body
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
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
                    // Glassmorphism Highlight
                    Positioned(
                      top: -40,
                      left: -40,
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
                        // Image with 3D Float animation
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
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _CategoryIconPanel(
                                            icon: icon,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          )
                              .animate(
                                  onPlay: (controller) =>
                                      controller.repeat(reverse: true))
                              .moveY(
                                  begin: -4,
                                  end: 4,
                                  duration: 2.seconds,
                                  curve: Curves.easeInOut),
                        ),

                        // Label
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
      child: Icon(
        icon,
        color: AppColors.deepGreen,
        size: 42,
      ),
    );
  }
}

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
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.lightText)),
          ],
        ),
      ),
    );
  }
}

class _NearbyBusinessCard extends ConsumerWidget {
  final Business business;
  const _NearbyBusinessCard({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamedBusiness =
        ref.watch(businessStreamProvider(business.id)).valueOrNull;
    final liveBusiness = streamedBusiness == null
        ? business
        : streamedBusiness.copyWith(
            distance: streamedBusiness.distance ?? business.distance);

    return GestureDetector(
      onTap: () => context.push('/business-details', extra: liveBusiness),
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
                offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(
                    liveBusiness.logoUrl ?? 'https://via.placeholder.com/150',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    liveBusiness.name,
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${liveBusiness.rating.toStringAsFixed(1)} (${liveBusiness.reviewCount})',
                        style: const TextStyle(
                            color: AppColors.lightText, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.circle, size: 4, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        liveBusiness.category.name.toUpperCase(),
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
              offset: const Offset(0, 10)),
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
                const Text('Scan for shops in your local arcade or street.',
                    style: TextStyle(color: AppColors.lightText, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
