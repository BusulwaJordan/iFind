import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:ifind/core/utils/distance_calculator.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/presentation/screens/create_business_screen.dart';
import 'package:ifind/features/business/presentation/screens/shop_gallery_screen.dart';
import 'package:ifind/features/business/presentation/screens/product_management_screen.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/needs/presentation/providers/need_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ifind/features/reviews/presentation/providers/review_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/widgets/app_drawer.dart';

class BusinessAnalytics {
  final int profileViews;
  final int inquiries;
  final int saved;
  final int activeLeads;
  final int conversations;
  final int products;
  final int availableProducts;
  final int lowStockProducts;
  final int portfolioItems;
  final int reviews;
  final double rating;
  final DateTime updatedAt;

  const BusinessAnalytics({
    required this.profileViews,
    required this.inquiries,
    required this.saved,
    required this.activeLeads,
    required this.conversations,
    required this.products,
    required this.availableProducts,
    required this.lowStockProducts,
    required this.portfolioItems,
    required this.reviews,
    required this.rating,
    required this.updatedAt,
  });

  factory BusinessAnalytics.empty(Business business) {
    return BusinessAnalytics(
      profileViews: 0,
      inquiries: 0,
      saved: 0,
      activeLeads: 0,
      conversations: 0,
      products: 0,
      availableProducts: 0,
      lowStockProducts: 0,
      portfolioItems: 0,
      reviews: business.reviewCount,
      rating: business.rating,
      updatedAt: DateTime.now(),
    );
  }

  int get reach => profileViews + saved;

  int get healthScore {
    final inventoryScore = products == 0 ? 0 : 20;
    final availabilityScore = products == 0
        ? 0
        : ((availableProducts / products).clamp(0.0, 1.0) * 20).round();
    final contentScore = portfolioItems == 0 ? 0 : 15;
    final ratingScore = ((rating / 5).clamp(0.0, 1.0) * 20).round();
    final demandScore =
        ((inquiries + activeLeads).clamp(0, 10) / 10 * 15).round();
    final trustScore = reviews == 0 ? 0 : 10;
    return (inventoryScore +
            availabilityScore +
            contentScore +
            ratingScore +
            demandScore +
            trustScore)
        .clamp(0, 100)
        .toInt();
  }
}

final businessAnalyticsProvider =
    StreamProvider.autoDispose.family<BusinessAnalytics, Business>(
  (ref, business) async* {
    var latest = BusinessAnalytics.empty(business);
    while (true) {
      latest = await _loadBusinessAnalytics(business, latest);
      yield latest;
      await Future<void>.delayed(const Duration(seconds: 8));
    }
  },
);

Future<BusinessAnalytics> _loadBusinessAnalytics(
  Business business,
  BusinessAnalytics fallback,
) async {
  try {
    final client = Supabase.instance.client;
    final since =
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

    final interactions = await _safeList(() => client
        .from('interactions')
        .select('interaction_type')
        .eq('business_id', business.id)
        .gte('created_at', since));
    final products = await _safeList(() => client
        .from('products')
        .select('is_available, stock_quantity')
        .eq('business_id', business.id));
    final portfolio = await _safeList(() => client
        .from('portfolio_items')
        .select('id')
        .eq('business_id', business.id));
    final chats = await _safeList(
        () => client.from('chats').select('id').eq('business_id', business.id));
    final needs = await _safeList(
        () => client.from('needs').select().eq('status', 'active').limit(80));

    int interactionCount(String type) => interactions
        .where((row) => row['interaction_type']?.toString() == type)
        .length;

    final matchingLeads = needs.where((row) {
      final category = row['category']?.toString() ?? '';
      final lat = (row['latitude'] as num?)?.toDouble();
      final lon = (row['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) return false;
      return businessCategoryForNeedCategory(category) == business.category &&
          DistanceCalculator.isWithinRadius(
            lat1: business.latitude,
            lon1: business.longitude,
            lat2: lat,
            lon2: lon,
            radiusInKm: 20,
          );
    }).length;

    final availableProducts =
        products.where((row) => row['is_available'] == true).length;
    final lowStockProducts = products.where((row) {
      final stock = (row['stock_quantity'] as num?)?.toInt() ?? 0;
      return stock <= 3;
    }).length;

    return BusinessAnalytics(
      profileViews: interactionCount('profile_view') + interactionCount('view'),
      inquiries: interactionCount('inquiry_sent'),
      saved: interactionCount('saved_business'),
      activeLeads: matchingLeads,
      conversations: chats.length,
      products: products.length,
      availableProducts: availableProducts,
      lowStockProducts: lowStockProducts,
      portfolioItems: portfolio.length,
      reviews: business.reviewCount,
      rating: business.rating,
      updatedAt: DateTime.now(),
    );
  } catch (_) {
    return fallback;
  }
}

Future<List<Map<String, dynamic>>> _safeList(
  Future<dynamic> Function() load,
) async {
  try {
    final data = await load();
    return (data as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  } catch (_) {
    return const [];
  }
}

class MyShopScreen extends ConsumerWidget {
  const MyShopScreen({super.key});

  Future<void> _deleteShop(
      BuildContext context, WidgetRef ref, String businessId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Delete Shop',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, color: Colors.red)),
          content: const Text(
              'This action is permanent. All your products, gallery media, and shop data will be deleted forever.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Delete Forever',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(businessRepositoryProvider);
      final user = ref.read(currentUserProvider);
      final result = await repository.deleteBusiness(businessId);

      result.fold(
        (failure) {
          if (context.mounted) {
            AppToast.show(context, friendlyError(Exception(failure.message)), type: ToastType.error);
          }
        },
        (_) {
          if (user != null) {
            ref.invalidate(myBusinessesProvider(user.id));
          }
          if (context.mounted) {
            AppToast.show(context, 'Shop deleted successfully', type: ToastType.success);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final myBusinessesAsync = ref.watch(myBusinessesStreamProvider(user.id));

    return Scaffold(
      backgroundColor:
          const Color(0xFFF0F4F8), // Slightly more tinted background
      drawer: const AppDrawer(),
      body: myBusinessesAsync.when(
        data: (businesses) {
          if (businesses.isEmpty) {
            return _buildEmptyState(context, ref, user.id);
          }

          final business = businesses.first;

          return Stack(
            children: [
              // Premium Background Accent
              Positioned(
                top: -120,
                right: -50,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryGreen.withValues(alpha: 0.15),
                        AppColors.primaryGreen.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myBusinessesStreamProvider(user.id));
                  return await ref
                      .read(myBusinessesStreamProvider(user.id).future);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(context, ref, business),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _buildQuickStats(context, business),
                            const SizedBox(height: 32),
                            _buildReviewsSection(context, business.id),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Business Command',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkText,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildAnalyticsDashboard(context, business),
                            const SizedBox(height: 24),
                            _buildManagementGrid(context, ref, business),
                            const SizedBox(height: 40),
                            _buildDangerZone(context, ref, business.id),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Menu button — sits below the back button in the AppBar's
              // leading slot so the two don't stack on top of each other.
              Positioned(
                top: 60,
                left: 0,
                child: SafeArea(
                  child: Builder(
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: IFindLoaderInline(size: 60)),
        error: (e, s) => _buildShopLoadError(context, ref, user.id),
      ),
    );
  }

  Widget _buildShopLoadError(
      BuildContext context, WidgetRef ref, String userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              'Could not load your business center',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and refresh.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey[600]),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.invalidate(myBusinessesStreamProvider(userId)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, String userId) {
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myBusinessesStreamProvider(userId)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: EmptyStateWidget(
            title: 'Start Your Business Workspace',
            message:
                'Create a shop with business contact details. Customer accounts are upgraded automatically when the first valid shop is submitted.',
            icon: Icons.handshake_rounded,
            actionLabel: 'Create Shop',
            onAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreateBusinessScreen())),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, WidgetRef ref, Business business) {
    final user = ref.read(currentUserProvider);
    final logoUrl = business.logoUrl ?? user?.avatarUrl;
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.deepGreen,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 20),
          ),
          // My Shop is a bottom-nav tab (not pushed on top of another
          // screen), so there's nothing on the Navigator stack to pop back
          // to — route to the dashboard tab instead.
          onPressed: () => context.go('/'),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.settings_outlined,
                  color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CreateBusinessScreen(business: business))),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (business.coverImageUrl != null)
              Image.network(business.coverImageUrl!, fit: BoxFit.cover)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.deepGreen, AppColors.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            // Fancy Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            // Shop Identity
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: logoUrl != null
                          ? Image.network(
                              logoUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.storefront_rounded,
                                color: AppColors.primaryGreen,
                                size: 40,
                              ),
                            )
                          : const Icon(Icons.storefront_rounded,
                              color: AppColors.primaryGreen, size: 40),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.name,
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: Text(
                            business.category.name.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, Business business) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.08),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem('Portfolio', business.reviewCount.toString(),
              Icons.auto_awesome_motion_rounded, const Color(0xFF6366F1)),
          Container(
              width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.1)),
          _buildStatItem('Rating', business.rating.toStringAsFixed(1),
              Icons.star_rounded, const Color(0xFFF59E0B)),
          Container(
              width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.1)),
          _buildStatItem(
              'Status', 'Active', Icons.bolt_rounded, const Color(0xFF10B981)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildReviewsSection(BuildContext context, String businessId) {
    return Consumer(
      builder: (context, ref, child) {
        final reviewsAsync = ref.watch(businessReviewsProvider(businessId));

        return reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.rate_review_rounded,
                          color: Colors.grey[300], size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No reviews yet',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        'Great service leads to great reviews!',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFEC4899).withValues(alpha: 0.06),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 24,
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
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Customer Reviews',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${reviews.length}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.take(3).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  review.authorName ?? 'Customer',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < review.rating
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (review.comment != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                review.comment!,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              timeago.format(review.createdAt,
                                  locale: 'en_short'),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (reviews.length > 3) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            AppToast.show(context, 'View all reviews feature coming soon!', type: ToastType.info),
                        child: Text(
                          'View all ${reviews.length} reviews',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: IFindLoaderInline(size: 60)),
          ),
          error: (e, s) => Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.rate_review_rounded,
                      color: Colors.grey[300], size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No reviews yet',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    'Great service leads to great reviews!',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementGrid(
      BuildContext context, WidgetRef ref, Business business) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      childAspectRatio: 1.45,
      children: [
        _buildManageCard(
          context,
          'Inventory',
          'Manage Inventory',
          Icons.inventory_2_rounded,
          const Color(0xFFF59E0B),
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ProductManagementScreen(businessId: business.id))),
        ),
        _buildManageCard(
          context,
          'Media Gallery',
          'Premium Visuals',
          Icons.auto_awesome_rounded,
          const Color(0xFFEC4899),
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ShopGalleryScreen(business: business))),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildAnalyticsDashboard(BuildContext context, Business business) {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsAsync = ref.watch(businessAnalyticsProvider(business));
        final analytics =
            analyticsAsync.valueOrNull ?? BusinessAnalytics.empty(business);
        final health = analytics.healthScore;
        final healthColor = health >= 75
            ? const Color(0xFF10B981)
            : health >= 45
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryGreen, AppColors.secondaryGreen],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 24,
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analytics Dashboard',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Live shop performance and customer demand',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _LiveStatusPill(updatedAt: analytics.updatedAt, light: true),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFB),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: healthColor.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Business health',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Text(
                          '$health%',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: healthColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: health / 100,
                        minHeight: 9,
                        backgroundColor: Colors.grey.withValues(alpha: 0.12),
                        color: healthColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _analyticsSuggestion(analytics),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final metricCards = [
                    _AnalyticsMetricCard(
                      label: 'Reach',
                      value: analytics.reach.toString(),
                      detail:
                          '${analytics.profileViews} views, ${analytics.saved} saves',
                      icon: Icons.visibility_rounded,
                      color: const Color(0xFF6366F1),
                    ),
                    _AnalyticsMetricCard(
                      label: 'Inquiries',
                      value: analytics.inquiries.toString(),
                      detail: '${analytics.conversations} active chats',
                      icon: Icons.forum_rounded,
                      color: const Color(0xFF0EA5E9),
                    ),
                    _AnalyticsMetricCard(
                      label: 'Open Leads',
                      value: analytics.activeLeads.toString(),
                      detail: 'Nearby matching needs',
                      icon: Icons.local_activity_rounded,
                      color: const Color(0xFF10B981),
                    ),
                    _AnalyticsMetricCard(
                      label: 'Inventory',
                      value:
                          '${analytics.availableProducts}/${analytics.products}',
                      detail: '${analytics.lowStockProducts} low stock',
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    _AnalyticsMetricCard(
                      label: 'Showcase',
                      value: analytics.portfolioItems.toString(),
                      detail: 'Gallery posts',
                      icon: Icons.auto_awesome_motion_rounded,
                      color: const Color(0xFFEC4899),
                    ),
                    _AnalyticsMetricCard(
                      label: 'Rating',
                      value: analytics.rating.toStringAsFixed(1),
                      detail: '${analytics.reviews} reviews',
                      icon: Icons.star_rounded,
                      color: const Color(0xFFF97316),
                    ),
                  ];

                  const spacing = 6.0;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final tileWidth = (constraints.maxWidth - spacing * 3) / 4;
                      return Column(
                        children: [
                          Row(
                            children: [
                              for (var i = 0; i < 4; i++) ...[
                                if (i > 0) const SizedBox(width: spacing),
                                SizedBox(width: tileWidth, child: metricCards[i]),
                              ],
                            ],
                          ),
                          const SizedBox(height: spacing),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: tileWidth, child: metricCards[4]),
                              const SizedBox(width: spacing),
                              SizedBox(width: tileWidth, child: metricCards[5]),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.06);
      },
    );
  }

  String _analyticsSuggestion(BusinessAnalytics analytics) {
    if (analytics.products == 0) {
      return 'Add products so customers can see what you sell before they message you.';
    }
    if (analytics.portfolioItems == 0) {
      return 'Add photos or short videos to make your shop easier to trust.';
    }
    if (analytics.lowStockProducts > 0) {
      return 'Restock low inventory items so interested customers do not bounce.';
    }
    if (analytics.activeLeads > 0) {
      return 'There are matching customer needs nearby. Open Customer Inquiries and respond early.';
    }
    if (analytics.inquiries == 0) {
      return 'Your shop is set up. Keep products and gallery fresh to attract the first inquiry.';
    }
    return 'Your shop has healthy signals. Keep replying fast and updating inventory.';
  }


  Widget _buildManageCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.darkText,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone(
      BuildContext context, WidgetRef ref, String businessId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepGreen, Color(0xFF0A5C36)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Account Security',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Retire Digital Shop',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'This will permanently unlist your business.',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _deleteShop(context, ref, businessId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: Text(
                  'Unlist',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _LiveStatusPill extends StatelessWidget {
  final DateTime updatedAt;
  final bool light;

  const _LiveStatusPill({required this.updatedAt, this.light = false});

  @override
  Widget build(BuildContext context) {
    final fgColor = light ? Colors.white : AppColors.primaryGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.15)
            : AppColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: fgColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            timeago.format(updatedAt, locale: 'en_short'),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  const _AnalyticsMetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 9,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
