import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/services/b2b_service.dart';
import 'package:ifind/core/utils/distance_calculator.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/presentation/providers/b2b_provider.dart';
import 'package:ifind/features/business/presentation/screens/create_business_screen.dart';
import 'package:ifind/features/business/presentation/screens/leads_dashboard.dart';
import 'package:ifind/features/business/presentation/screens/shop_gallery_screen.dart';
import 'package:ifind/features/business/presentation/screens/product_management_screen.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/needs/presentation/providers/need_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ifind/features/reviews/presentation/providers/review_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  static final _partnerSectionKey = GlobalKey();

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Sign Out',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Sign Out',
                  style: GoogleFonts.outfit(
                      color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

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
                            _buildQuickStats(business),
                            const SizedBox(height: 32),
                            _buildReviewsSection(business.id),
                            const SizedBox(height: 32),
                            _buildPartnerRecommendations(context, business),
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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
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
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.deepGreen,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
        ),
        onPressed: () => _handleSignOut(context, ref),
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
                      child: business.logoUrl != null
                          ? Image.network(business.logoUrl!, fit: BoxFit.cover)
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
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
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

  Widget _buildQuickStats(Business business) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
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

  Widget _buildReviewsSection(String businessId) {
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
                  color: Colors.white,
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
                color: Colors.white,
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
          loading: () => Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Text('Unable to load reviews'),
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
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.05,
      children: [
        _buildManageCard(
          'Customer Inquiries',
          'Messages & Actions',
          Icons.bubble_chart_rounded,
          const Color(0xFF6366F1),
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LeadsDashboardScreen())),
        ),
        _buildManageCard(
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
            color: Colors.white,
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: AppColors.primaryGreen,
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
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          'Live shop performance and customer demand',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _LiveStatusPill(updatedAt: analytics.updatedAt),
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
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
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
                ],
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

  Widget _buildPartnerRecommendations(BuildContext context, Business business) {
    return Consumer(
      builder: (context, ref, child) {
        final partnersAsync = ref.watch(b2bPartnerCandidatesProvider(business));
        final user = ref.watch(currentUserProvider);

        return Container(
          key: _partnerSectionKey,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
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
                  Expanded(
                    child: Text(
                      'B2B Partner Matches',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  const Icon(Icons.near_me_rounded,
                      color: AppColors.primaryGreen, size: 20),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Best nearby businesses for supply, referral, and service partnerships.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              partnersAsync.when(
                data: (partners) {
                  final candidates = partners.take(5).toList();

                  if (candidates.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          'As more verified businesses join nearby, your strongest partner matches will appear here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[500],
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: candidates.map((partner) {
                      final matchAsync = ref.watch(
                        b2bCompatibilityProvider((
                          myBusiness: business,
                          targetBusiness: partner,
                        )),
                      );

                      return _PartnerMatchTile(
                        partner: partner,
                        matchAsync: matchAsync,
                        onMessage: user == null
                            ? null
                            : () async {
                                try {
                                  final chat = await ref
                                      .read(chatRemoteDataSourceProvider)
                                      .getOrCreateChat(
                                        customerId: user.id,
                                        businessId: partner.id,
                                      );

                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatRoomScreen(
                                          chat: chat,
                                          otherPartyName: partner.name,
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
                      );
                    }).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'Unable to load partner matches right now.',
                    style: GoogleFonts.outfit(color: Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08);
      },
    );
  }

  Widget _buildManageCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: AppColors.darkText,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(
                'Account Security',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
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
                        color: AppColors.darkText,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'This will permanently unlist your business.',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _deleteShop(context, ref, businessId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(
                  'Unlist',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _PartnerMatchTile extends StatelessWidget {
  final Business partner;
  final AsyncValue<B2bCompatibilityResult> matchAsync;
  final VoidCallback? onMessage;

  const _PartnerMatchTile({
    required this.partner,
    required this.matchAsync,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final distanceLabel = partner.distance == null
        ? 'Nearby'
        : '${partner.distance!.toStringAsFixed(1)} km';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${partner.category.name.toUpperCase()} • $distanceLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                matchAsync.when(
                  data: (match) {
                    final percent = (match.compatibilityScore * 100).round();
                    return Text(
                      '$percent% partner fit',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    );
                  },
                  loading: () => Text(
                    'Checking partner fit...',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  error: (_, __) => Text(
                    'Recommended nearby',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Message partner',
            onPressed: onMessage,
            icon: const Icon(Icons.forum_rounded),
            color: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }
}

class _LiveStatusPill extends StatelessWidget {
  final DateTime updatedAt;

  const _LiveStatusPill({required this.updatedAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            timeago.format(updatedAt, locale: 'en_short'),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 13,
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
              fontSize: 10,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
