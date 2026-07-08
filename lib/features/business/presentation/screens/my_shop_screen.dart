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
import 'package:ifind/features/needs/domain/entities/need.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ifind/features/reviews/presentation/providers/review_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/widgets/app_drawer.dart';
import 'package:ifind/features/products/presentation/screens/add_product_screen.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:ifind/features/portfolio/presentation/providers/portfolio_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Business Analytics (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

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

    // products.business_id and portfolio_items.business_id are the UUID
    // primary key on businesses, not the custom text id (e.g. "BIZ0122")
    // used everywhere else — resolve it before querying those two tables,
    // matching the pattern already used in ProductRemoteDataSource and
    // PortfolioRepository.
    final businessRow = await client
        .from('businesses')
        .select('id')
        .eq('business_id', business.id)
        .maybeSingle();
    final businessUuid = businessRow?['id'] as String? ?? business.id;

    final interactions = await _safeList(() => client
        .from('interactions')
        .select('interaction_type')
        .eq('business_id', business.id)
        .gte('timestamp', since));
    final products = await _safeList(() => client
        .from('products')
        .select('is_available, stock_quantity')
        .eq('business_id', businessUuid));
    final portfolio = await _safeList(() => client
        .from('portfolio_items')
        .select('id')
        .eq('business_id', businessUuid));
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

// ─────────────────────────────────────────────────────────────────────────────
// MyShopScreen
// ─────────────────────────────────────────────────────────────────────────────

class MyShopScreen extends ConsumerStatefulWidget {
  const MyShopScreen({super.key});

  @override
  ConsumerState<MyShopScreen> createState() => _MyShopScreenState();
}

class _MyShopScreenState extends ConsumerState<MyShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _scrollController;
  int _selectedTab = 0;
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController = ScrollController();
    _tabController.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() => _selectedTab = _tabController.index);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _deleteShop(BuildContext context, String businessId) async {
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
            AppToast.show(context, friendlyError(Exception(failure.message)),
                type: ToastType.error);
          }
        },
        (_) {
          if (user != null) {
            ref.invalidate(myBusinessesProvider(user.id));
          }
          if (context.mounted) {
            AppToast.show(context, 'Shop deleted successfully',
                type: ToastType.success);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final myBusinessesAsync = ref.watch(myBusinessesStreamProvider(user.id));

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF0F7F4),
      body: myBusinessesAsync.when(
        data: (businesses) {
          if (businesses.isEmpty) {
            return _buildEmptyState(context, user.id);
          }
          final business = businesses.first;
          return _buildShopBody(context, business);
        },
        loading: () => const Center(child: IFindLoaderInline(size: 60)),
        error: (e, s) => _buildShopLoadError(context, user.id),
      ),
    );
  }

  Widget _buildShopLoadError(BuildContext context, String userId) {
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

  Widget _buildEmptyState(BuildContext context, String userId) {
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

  Widget _buildShopBody(BuildContext context, Business business) {
    final topPad = MediaQuery.of(context).padding.top;
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: topPad + kToolbarHeight + 272.0,
          backgroundColor: AppColors.deepGreen,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () => context.go('/'),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          title: Text(
            'My Shop Profile',
            style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: _buildPageHeader(context, business),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: AppColors.deepGreen,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicatorColor: Colors.white,
                indicatorWeight: 2.5,
                labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                labelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
                tabs: const [
                  Tab(
                      icon: Icon(Icons.bar_chart_rounded, size: 16),
                      text: 'Overview',
                      iconMargin: EdgeInsets.only(bottom: 2)),
                  Tab(
                      icon: Icon(Icons.shopping_bag_outlined, size: 16),
                      text: 'Products',
                      iconMargin: EdgeInsets.only(bottom: 2)),
                  Tab(
                      icon: Icon(Icons.star_border_rounded, size: 16),
                      text: 'Reviews',
                      iconMargin: EdgeInsets.only(bottom: 2)),
                  Tab(
                      icon: Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      text: 'Inquiries',
                      iconMargin: EdgeInsets.only(bottom: 2)),
                  Tab(
                      icon: Icon(Icons.insert_chart_outlined_rounded, size: 16),
                      text: 'Analytics',
                      iconMargin: EdgeInsets.only(bottom: 2)),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildStatsBar(context, business)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            child: _buildTabContent(context, business),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context, Business business) {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewContent(context, business);
      case 1:
        return _buildProductsContent(context, business);
      case 2:
        return _buildReviewsContent(context, business);
      case 3:
        return _buildInquiriesContent(context, business);
      case 4:
        return _AnalyticsTab(business: business);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Header with background image + green overlay (like login page) ───────────

  Widget _buildPageHeader(BuildContext context, Business business) {
    final topPad = MediaQuery.of(context).padding.top;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Cover photo (user-uploaded) → default asset fallback
        if (business.coverImageUrl != null)
          Image.network(
            business.coverImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/Color Gradient T-shirts Display.png',
              fit: BoxFit.cover,
            ),
          )
        else
          Image.asset(
            'assets/images/Color Gradient T-shirts Display.png',
            fit: BoxFit.cover,
          ),
        // Green gradient overlay — same pattern as login page
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF064E3B).withValues(alpha: 0.92),
                const Color(0xFF10B981).withValues(alpha: 0.48),
                const Color(0xFF064E3B).withValues(alpha: 0.96),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Business info content — pushed below the pinned app bar row
        Padding(
          padding:
              EdgeInsets.fromLTRB(16, topPad + kToolbarHeight + 10, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: business.logoUrl != null
                              ? Image.network(business.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                        Icons.storefront_rounded,
                                        size: 36,
                                        color: AppColors.primaryGreen,
                                      ))
                              : const Icon(Icons.storefront_rounded,
                                  size: 36, color: AppColors.primaryGreen),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 11, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                business.name,
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 5),
                            if (business.isVerified)
                              const Icon(Icons.verified,
                                  color: Colors.lightGreenAccent, size: 18),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white38),
                          ),
                          child: Text('Business Member',
                              style: GoogleFonts.outfit(
                                  color: Colors.white, fontSize: 11)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: Colors.white70, size: 13),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                business.address ?? 'Uganda',
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Text('  ·  ',
                                style: TextStyle(color: Colors.white54)),
                            Text('Open',
                                style: GoogleFonts.outfit(
                                    color: Colors.lightGreenAccent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFBBF24), size: 14),
                            const SizedBox(width: 3),
                            Text(
                              '${business.rating.toStringAsFixed(1)} (${business.reviewCount})',
                              style: GoogleFonts.outfit(
                                  color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CreateBusinessScreen(business: business))),
                  icon: const Icon(Icons.edit_outlined,
                      size: 15, color: AppColors.primaryGreen),
                  label: Text('Edit Profile',
                      style: GoogleFonts.outfit(
                          color: AppColors.primaryGreen, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Floating stats bar ──────────────────────────────────────────────────────

  Widget _buildStatsBar(BuildContext context, Business business) {
    final analyticsAsync = ref.watch(businessAnalyticsProvider(business));
    final a = analyticsAsync.valueOrNull ?? BusinessAnalytics.empty(business);
    // Same count shown on the Inquiries tab below (businessLeadsProvider),
    // not the 30-day interaction log — that's a different, less useful number.
    final inquiriesCount =
        ref.watch(businessLeadsProvider(business)).valueOrNull?.length ?? 0;

    final stats = [
      (
        icon: Icons.visibility_outlined,
        value: a.profileViews.toString(),
        label: 'Views',
        color: const Color(0xFF3B82F6),
      ),
      (
        icon: Icons.chat_bubble_outline_rounded,
        value: inquiriesCount.toString(),
        label: 'Inquiries',
        color: const Color(0xFFF59E0B),
      ),
      (
        icon: Icons.shopping_bag_outlined,
        value: a.products.toString(),
        label: 'Listings',
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepGreen.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: stats
              .map(
                (s) => Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: s.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(s.icon, color: s.color, size: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.value,
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText),
                      ),
                      Text(
                        s.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // ── Overview tab content ────────────────────────────────────────────────────

  Widget _buildOverviewContent(BuildContext context, Business business) {
    final profileScore = _calcProfileScore(business);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _twoColumn(
          left: _buildShopInfoCard(context, business,
              accentColor: const Color(0xFF3B82F6)),
          right: _buildCompletionCard(context, business, profileScore,
              accentColor: AppColors.primaryGreen),
        ),
        const SizedBox(height: 12),
        _twoColumn(
          left: _buildGalleryCard(context, business,
              accentColor: const Color(0xFFF59E0B)),
          right: _buildAboutCard(context, business,
              accentColor: const Color(0xFF8B5CF6)),
          matchHeight: false,
        ),
        const SizedBox(height: 12),
        _buildQuickActionsWidget(context, business),
        const SizedBox(height: 12),
        _buildDangerZoneWidget(context, business),
      ],
    );
  }

  // matchHeight uses IntrinsicHeight to make both cards the same height —
  // skip it for pairs where one side can grow to an unbounded height (e.g.
  // an expanded "Read More" description), since IntrinsicHeight can't
  // reconcile that with the final layout pass and overflows.
  Widget _twoColumn(
      {required Widget left, required Widget right, bool matchHeight = true}) {
    return LayoutBuilder(builder: (ctx, constraints) {
      if (constraints.maxWidth > 680) {
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: left),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: right),
          ],
        );
        return matchHeight ? IntrinsicHeight(child: row) : row;
      }
      return Column(children: [left, const SizedBox(height: 12), right]);
    });
  }

  Widget _shopCard({
    required BuildContext context,
    required String title,
    required Widget child,
    String? action,
    VoidCallback? onAction,
    Color accentColor = AppColors.primaryGreen,
    Color? backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored accent strip at top
          Container(
            height: 4,
            width: double.infinity,
            color: accentColor,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(title,
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkText)),
                          ),
                        ],
                      ),
                    ),
                    if (action != null && onAction != null)
                      GestureDetector(
                        onTap: onAction,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(action,
                              style: GoogleFonts.outfit(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopInfoCard(BuildContext context, Business business,
      {Color accentColor = AppColors.primaryGreen}) {
    final catLabel = business.category.name[0].toUpperCase() +
        business.category.name.substring(1);
    return _shopCard(
      context: context,
      title: 'Shop Information',
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.storefront_outlined,
            color: const Color(0xFF6366F1),
            label: 'Category',
            value: catLabel,
          ),
          if (business.address != null)
            _InfoRow(
              icon: Icons.location_on_outlined,
              color: const Color(0xFFEC4899),
              label: 'Address',
              value: business.address!,
            ),
          if (business.phone != null)
            _InfoRow(
              icon: Icons.call_outlined,
              color: const Color(0xFF10B981),
              label: 'Phone',
              value: business.phone!,
            ),
          if (business.email != null)
            _InfoRow(
              icon: Icons.mail_outline_rounded,
              color: const Color(0xFF3B82F6),
              label: 'Email',
              value: business.email!,
            ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CreateBusinessScreen(business: business))),
            child: Text('View Full Details  →',
                style: GoogleFonts.outfit(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(
      BuildContext context, Business business, int profileScore,
      {Color accentColor = AppColors.primaryGreen}) {
    return _shopCard(
      context: context,
      title: 'Shop Completion',
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: profileScore / 100,
                      strokeWidth: 7,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryGreen),
                    ),
                    Center(
                      child: Text(
                        '$profileScore%',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Almost there!',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                            fontSize: 12)),
                    const SizedBox(height: 3),
                    Text(
                      'Complete your profile to get more visibility and leads.',
                      style: GoogleFonts.outfit(
                          fontSize: 10, color: Colors.grey[600], height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _CheckItem(done: true, label: 'Add Shop Logo'),
          _CheckItem(
              done: business.description.length >= 20,
              label: 'Add Business Description'),
          _CheckItem(done: business.logoUrl != null, label: 'Add Logo Image'),
          _CheckItem(
              done: business.coverImageUrl != null, label: 'Add Cover Photo'),
          _CheckItem(
              done: business.phone != null || business.email != null,
              label: 'Add Contact Info'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CreateBusinessScreen(business: business))),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Complete Profile',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryCard(BuildContext context, Business business,
      {Color accentColor = AppColors.primaryGreen}) {
    final portfolioAsync = ref.watch(portfolioProvider(business.id));
    final items = portfolioAsync.valueOrNull ?? [];
    final showCount = items.length.clamp(0, 5);
    final extra = items.length - showCount;

    return _shopCard(
      context: context,
      title: 'Shop Gallery',
      action: 'Manage Photos',
      accentColor: accentColor,
      onAction: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ShopGalleryScreen(business: business))),
      child: SizedBox(
        height: 82,
        child: items.isEmpty
            ? Container(
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: accentColor.withValues(alpha: 0.15),
                      style: BorderStyle.solid),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: accentColor, size: 24),
                      const SizedBox(height: 4),
                      Text('Add gallery photos',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: accentColor)),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: showCount,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final isLast = i == showCount - 1 && extra > 0;
                  final imageUrl = item.thumbnailUrl ?? item.mediaUrl;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 76,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: accentColor.withValues(alpha: 0.08),
                              child: Icon(Icons.image_outlined,
                                  color: accentColor, size: 22),
                            ),
                          ),
                          if (isLast)
                            Container(
                              color: Colors.black.withValues(alpha: 0.5),
                              child: Center(
                                child: Text('+$extra',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, Business business,
      {Color accentColor = AppColors.primaryGreen}) {
    return _shopCard(
      context: context,
      title: 'Business Description',
      action: 'Edit',
      accentColor: accentColor,
      onAction: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CreateBusinessScreen(business: business))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            business.description.isEmpty
                ? 'No description yet. Add one to help customers find you.'
                : business.description,
            style: GoogleFonts.outfit(
                fontSize: 12, color: Colors.grey[700], height: 1.4),
            maxLines: _descExpanded ? null : 5,
            overflow:
                _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (business.description.length > 100) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Text(
                _descExpanded ? 'Show Less  ⌃' : 'Read More  ⌄',
                style: GoogleFonts.outfit(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionsWidget(BuildContext context, Business business) {
    const tileColors = [
      Color(0xFF10B981), // Add Product — green
      Color(0xFFF59E0B), // View Inquiries — amber
      Color(0xFF8B5CF6), // Manage Products — purple
      Color(0xFF6366F1), // Shop Settings — indigo
    ];

    final actions = [
      (
        icon: Icons.add_box_outlined,
        label: 'Add Product',
        badge: null as int?,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddProductScreen(businessId: business.id)))
      ),
      (
        icon: Icons.chat_bubble_outline_rounded,
        label: 'View Inquiries',
        badge: null as int?,
        onTap: () => setState(() {
              _selectedTab = 3;
              _tabController.animateTo(3);
            })
      ),
      (
        icon: Icons.inventory_2_outlined,
        label: 'Manage Products',
        badge: null as int?,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ProductManagementScreen(businessId: business.id)))
      ),
      (
        icon: Icons.settings_outlined,
        label: 'Shop Settings',
        badge: null as int?,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CreateBusinessScreen(business: business)))
      ),
    ];

    return _shopCard(
      context: context,
      title: 'Quick Actions',
      accentColor: const Color(0xFF6366F1),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.1,
        ),
        itemCount: actions.length,
        itemBuilder: (ctx, i) {
          final a = actions[i];
          final color = tileColors[i];
          return GestureDetector(
            onTap: a.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.20)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(a.icon, color: color, size: 13),
                        ),
                        const SizedBox(height: 3),
                        Text(a.label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkText)),
                      ],
                    ),
                  ),
                  if (a.badge != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.redAccent, shape: BoxShape.circle),
                        child: Text('${a.badge}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 9)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildDangerZoneWidget(BuildContext context, Business business) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delete Shop',
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700])),
                const SizedBox(height: 3),
                Text(
                  'Permanently remove this shop and all its data.',
                  style:
                      GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _deleteShop(context, business.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text('Delete',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Products tab ────────────────────────────────────────────────────────────

  Widget _buildProductsContent(BuildContext context, Business business) {
    final analyticsAsync = ref.watch(businessAnalyticsProvider(business));
    final analytics =
        analyticsAsync.valueOrNull ?? BusinessAnalytics.empty(business);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_rounded,
                color: AppColors.primaryGreen, size: 48),
          ),
          const SizedBox(height: 16),
          Text('Manage Your Products',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Add, edit, and manage your product inventory.',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _ProductStat(
                label: 'Total',
                value: analytics.products.toString(),
                color: const Color(0xFF10B981)),
            Container(
                width: 1,
                height: 32,
                color: Colors.grey.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(horizontal: 16)),
            _ProductStat(
                label: 'Available',
                value: analytics.availableProducts.toString(),
                color: const Color(0xFF3B82F6)),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ProductManagementScreen(businessId: business.id))),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text('Open Product Manager',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reviews tab ─────────────────────────────────────────────────────────────

  Widget _buildReviewsContent(BuildContext context, Business business) {
    final reviewsAsync = ref.watch(businessReviewsProvider(business.id));
    return reviewsAsync.when(
      loading: () => const Center(
          child: Padding(
              padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
      error: (_, __) => const EmptyStateWidget(
          title: 'No Reviews Yet',
          message: 'Great service leads to great reviews!',
          icon: Icons.rate_review_rounded),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const EmptyStateWidget(
              title: 'No Reviews Yet',
              message: 'Great service leads to great reviews!',
              icon: Icons.rate_review_rounded);
        }
        return Column(
          children: reviews
              .map((review) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.1),
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
                            Text(review.authorName ?? 'Customer',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.darkText)),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < review.rating
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (review.comment != null) ...[
                          const SizedBox(height: 8),
                          Text(review.comment!,
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.4)),
                        ],
                        const SizedBox(height: 6),
                        Text(timeago.format(review.createdAt),
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  // ── Inquiries tab ───────────────────────────────────────────────────────────

  Widget _buildInquiriesContent(BuildContext context, Business business) {
    final leadsAsync = ref.watch(businessLeadsProvider(business));
    return leadsAsync.when(
      loading: () => const Center(
          child: Padding(
              padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
      error: (_, __) => const EmptyStateWidget(
          title: 'No Inquiries Yet',
          message: 'Customer inquiries matching your shop will appear here.',
          icon: Icons.forum_rounded),
      data: (needs) {
        if (needs.isEmpty) {
          return const EmptyStateWidget(
              title: 'No Inquiries Yet',
              message: 'Customer inquiries will appear here.',
              icon: Icons.forum_rounded);
        }
        return Column(
          children: needs
              .map((need) => _InquiryCard(need: need, business: business))
              .toList(),
        );
      },
    );
  }

  Widget _buildHeroBackground(BuildContext context, Business business) {
    final logoUrl = business.logoUrl;
    final catLabel = business.category.name[0].toUpperCase() +
        business.category.name.substring(1);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Cover image or gradient fallback
        if (business.coverImageUrl != null)
          Image.network(
            business.coverImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.deepGreen, AppColors.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          )
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
        // 2. Dark scrim
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        // 3. Business info
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Logo (80×80 rounded square, white border)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: logoUrl != null
                          ? Image.network(logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                    Icons.storefront_rounded,
                                    color: AppColors.primaryGreen,
                                    size: 40,
                                  ))
                          : const Icon(Icons.storefront_rounded,
                              color: AppColors.primaryGreen, size: 40),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + verified badge, category chip, location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                business.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded,
                                color: Color(0xFF60A5FA), size: 18),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryGreen.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            catLabel,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (business.address != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.white70, size: 12),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  business.address!,
                                  style: GoogleFonts.outfit(
                                      fontSize: 11, color: Colors.white70),
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
                ],
              ),
              const SizedBox(height: 10),
              // Rating stars + review count + followers badge
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < business.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFFBBF24),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${business.rating.toStringAsFixed(1)} (${business.reviewCount})',
                    style:
                        GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text('·',
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '0 followers',
                      style:
                          GoogleFonts.outfit(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Edit Profile button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CreateBusinessScreen(business: business))),
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 16),
                  label: Text('Edit Profile',
                      style: GoogleFonts.outfit(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 0: Overview ────────────────────────────────────────────────────────

  Widget _buildOverviewTab(BuildContext context, Business business) {
    final analyticsAsync = ref.watch(businessAnalyticsProvider(business));
    final analytics =
        analyticsAsync.valueOrNull ?? BusinessAnalytics.empty(business);
    final profileScore = _calcProfileScore(business);

    return Builder(
      builder: (context) => CustomScrollView(
        key: const PageStorageKey<String>('tab_overview'),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Performance Overview
                _SectionCard(
                  title: 'Performance Overview',
                  icon: Icons.bar_chart_rounded,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _PerformanceMetricCard(
                          label: 'Profile Views',
                          value: analytics.profileViews.toString(),
                          icon: Icons.visibility_rounded,
                          color: const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 10),
                        _PerformanceMetricCard(
                          label: 'Inquiries',
                          value: analytics.inquiries.toString(),
                          icon: Icons.forum_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 10),
                        _PerformanceMetricCard(
                          label: 'Products',
                          value: analytics.products.toString(),
                          icon: Icons.inventory_2_rounded,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 10),
                        _PerformanceMetricCard(
                          label: 'Saved',
                          value: analytics.saved.toString(),
                          icon: Icons.bookmark_rounded,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Shop Information
                _SectionCard(
                  title: 'Shop Information',
                  icon: Icons.info_outline_rounded,
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.category_rounded,
                        color: const Color(0xFF6366F1),
                        label: 'Category',
                        value: business.category.name[0].toUpperCase() +
                            business.category.name.substring(1),
                      ),
                      if (business.address != null)
                        _InfoRow(
                          icon: Icons.location_on_rounded,
                          color: const Color(0xFFEC4899),
                          label: 'Address',
                          value: business.address!,
                        ),
                      if (business.phone != null)
                        _InfoRow(
                          icon: Icons.phone_rounded,
                          color: const Color(0xFF10B981),
                          label: 'Phone',
                          value: business.phone!,
                        ),
                      if (business.email != null)
                        _InfoRow(
                          icon: Icons.email_rounded,
                          color: const Color(0xFF3B82F6),
                          label: 'Email',
                          value: business.email!,
                        ),
                      if (business.website != null)
                        _InfoRow(
                          icon: Icons.language_rounded,
                          color: const Color(0xFFF59E0B),
                          label: 'Website',
                          value: business.website!,
                        ),
                    ],
                  ),
                ),

                // 3. Profile Completion
                _SectionCard(
                  title: 'Profile Completeness',
                  icon: Icons.task_alt_rounded,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: profileScore / 100,
                              backgroundColor:
                                  Colors.grey.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryGreen),
                              strokeWidth: 6,
                            ),
                            Text(
                              '$profileScore%',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _CheckItem(
                                done: true, label: 'Business Name'),
                            _CheckItem(
                              done: business.description.length >= 20,
                              label: 'Description',
                            ),
                            _CheckItem(
                              done: business.logoUrl != null,
                              label: 'Logo',
                            ),
                            _CheckItem(
                              done: business.coverImageUrl != null,
                              label: 'Cover Photo',
                            ),
                            _CheckItem(
                              done: business.phone != null ||
                                  business.email != null,
                              label: 'Phone or Email',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Gallery Preview
                _SectionCard(
                  title: 'Shop Gallery',
                  icon: Icons.photo_library_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Showcase your products and space with photos.',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ShopGalleryScreen(business: business))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Manage Photos',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Business Description
                _SectionCard(
                  title: 'About',
                  icon: Icons.description_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.description.isEmpty
                            ? 'No description yet.'
                            : business.description,
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.grey[700], height: 1.5),
                        maxLines: _descExpanded ? null : 4,
                        overflow: _descExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                      if (business.description.length > 120)
                        TextButton(
                          onPressed: () =>
                              setState(() => _descExpanded = !_descExpanded),
                          child: Text(
                            _descExpanded ? 'Show Less' : 'Read More',
                            style: GoogleFonts.outfit(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    CreateBusinessScreen(business: business))),
                        icon: const Icon(Icons.edit_outlined,
                            size: 16, color: AppColors.primaryGreen),
                        label: Text('Edit Description',
                            style: GoogleFonts.outfit(
                                color: AppColors.primaryGreen)),
                      ),
                    ],
                  ),
                ),

                // 6. Quick Actions Grid (2×3)
                _SectionCard(
                  title: 'Quick Actions',
                  icon: Icons.grid_view_rounded,
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                    children: [
                      _QuickActionTile(
                        label: 'Add Product',
                        icon: Icons.add_box_rounded,
                        color: const Color(0xFF10B981),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    AddProductScreen(businessId: business.id))),
                      ),
                      _QuickActionTile(
                        label: 'Products',
                        icon: Icons.inventory_2_rounded,
                        color: const Color(0xFFF59E0B),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ProductManagementScreen(
                                    businessId: business.id))),
                      ),
                      _QuickActionTile(
                        label: 'Gallery',
                        icon: Icons.photo_library_rounded,
                        color: const Color(0xFF6366F1),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ShopGalleryScreen(business: business))),
                      ),
                      _QuickActionTile(
                        label: 'Reviews',
                        icon: Icons.star_rounded,
                        color: const Color(0xFFEC4899),
                        onTap: () => _tabController.animateTo(2),
                      ),
                      _QuickActionTile(
                        label: 'Inquiries',
                        icon: Icons.forum_rounded,
                        color: const Color(0xFF3B82F6),
                        onTap: () => _tabController.animateTo(3),
                      ),
                      _QuickActionTile(
                        label: 'Edit Shop',
                        icon: Icons.edit_rounded,
                        color: const Color(0xFF8B5CF6),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    CreateBusinessScreen(business: business))),
                      ),
                    ],
                  ),
                ),

                // 7. Promotion Banner
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.deepGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get More Visibility',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Promote your shop to reach more customers in your area and increase sales.',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.white70, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => AppToast.show(
                              context, 'Promotion feature coming soon!',
                              type: ToastType.info),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.deepGreen,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Promote Now',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                // 8. Danger Zone
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.deepGreen, Color(0xFF0A5C36)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Shop',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Permanently remove this shop.',
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _deleteShop(context, business.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Delete',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Products ────────────────────────────────────────────────────────

  Widget _buildProductsTab(BuildContext context, Business business) {
    final analyticsAsync = ref.watch(businessAnalyticsProvider(business));
    final analytics =
        analyticsAsync.valueOrNull ?? BusinessAnalytics.empty(business);

    return Builder(
      builder: (context) => CustomScrollView(
        key: const PageStorageKey<String>('tab_products'),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2_rounded,
                              color: AppColors.primaryGreen, size: 48),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Manage Your Products',
                          style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add, edit, and manage your product inventory.',
                          style: GoogleFonts.outfit(
                              fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ProductStat(
                              label: 'Total',
                              value: analytics.products.toString(),
                              color: const Color(0xFF10B981),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: Colors.grey.withValues(alpha: 0.2),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            _ProductStat(
                              label: 'Available',
                              value: analytics.availableProducts.toString(),
                              color: const Color(0xFF3B82F6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ProductManagementScreen(
                                        businessId: business.id))),
                            icon:
                                const Icon(Icons.open_in_new_rounded, size: 18),
                            label: Text('Open Product Manager',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Reviews ─────────────────────────────────────────────────────────

  Widget _buildReviewsTab(BuildContext context, Business business) {
    final reviewsAsync = ref.watch(businessReviewsProvider(business.id));

    return Builder(
      builder: (context) => CustomScrollView(
        key: const PageStorageKey<String>('tab_reviews'),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: reviewsAsync.when(
              data: (reviews) {
                if (reviews.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyStateWidget(
                        title: 'No Reviews Yet',
                        message: 'Great service leads to great reviews!',
                        icon: Icons.rate_review_rounded,
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final review = reviews[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.1),
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
                                Text(
                                  review.authorName ?? 'Customer',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (review.comment != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                review.comment!,
                                style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.4),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              timeago.format(review.createdAt),
                              style: GoogleFonts.outfit(
                                  fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: reviews.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyStateWidget(
                    title: 'No Reviews Yet',
                    message: 'Great service leads to great reviews!',
                    icon: Icons.rate_review_rounded,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Inquiries ───────────────────────────────────────────────────────

  Widget _buildInquiriesTab(BuildContext context, Business business) {
    final leadsAsync = ref.watch(businessLeadsProvider(business));

    return Builder(
      builder: (context) => CustomScrollView(
        key: const PageStorageKey<String>('tab_inquiries'),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: leadsAsync.when(
              data: (needs) {
                if (needs.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyStateWidget(
                        title: 'No Inquiries Yet',
                        message:
                            'Customer inquiries matching your shop will appear here.',
                        icon: Icons.forum_rounded,
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _InquiryCard(
                      need: needs[index],
                      business: business,
                    ),
                    childCount: needs.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyStateWidget(
                    title: 'No Inquiries Yet',
                    message: 'Customer inquiries will appear here.',
                    icon: Icons.forum_rounded,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 4: Analytics ───────────────────────────────────────────────────────

  Widget _buildAnalyticsTab(BuildContext context, Business business) {
    return Builder(
      builder: (context) => CustomScrollView(
        key: const PageStorageKey<String>('tab_analytics'),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _AnalyticsTab(business: business),
            ),
          ),
        ],
      ),
    );
  }

  int _calcProfileScore(Business business) {
    int s = 20;
    if (business.description.length >= 20) s += 20;
    if (business.logoUrl != null) s += 20;
    if (business.coverImageUrl != null) s += 20;
    if (business.phone != null || business.email != null) s += 20;
    return s;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  const _SectionCard({required this.title, required this.child, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primaryGreen, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: Colors.grey[500])),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
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

class _CheckItem extends StatelessWidget {
  final bool done;
  final String label;
  const _CheckItem({required this.done, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: done ? AppColors.primaryGreen : Colors.grey[400],
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: done ? AppColors.darkText : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PerformanceMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText),
              ),
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: Colors.grey[500])),
              Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, color: color, size: 10),
                  Text(' this month',
                      style: GoogleFonts.outfit(fontSize: 10, color: color)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
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
      ),
    );
  }
}

class _ProductStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ProductStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 28, fontWeight: FontWeight.w900, color: color)),
        Text(label,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inquiry Card (Tab 3)
// ─────────────────────────────────────────────────────────────────────────────

class _InquiryCard extends ConsumerWidget {
  final Need need;
  final Business business;
  const _InquiryCard({required this.need, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(userProfileProvider(need.userId));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 10),
          Text(
            need.title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          if (need.description != null && need.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              need.description!,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: Colors.grey[700], height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
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
                final customer = customerAsync.value;
                if (customer == null) {
                  messenger.showSnackBar(const SnackBar(
                      content: Text('Customer profile is still loading.')));
                  return;
                }
                try {
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
                          otherPartyName: customer.fullName,
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
// Analytics Tab widget (Tab 4)
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyticsTab extends ConsumerWidget {
  final Business business;
  const _AnalyticsTab({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                child: const Icon(Icons.analytics_rounded, color: Colors.white),
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
              border: Border.all(color: healthColor.withValues(alpha: 0.16)),
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
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 6.0;
              final tileWidth = (constraints.maxWidth - spacing * 3) / 4;
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
                  value: '${analytics.availableProducts}/${analytics.products}',
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
          ),
        ],
      ),
    ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.06);
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Reused widgets from original (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

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
