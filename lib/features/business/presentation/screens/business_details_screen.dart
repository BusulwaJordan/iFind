import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/presentation/providers/b2b_provider.dart';
import 'package:ifind/features/portfolio/presentation/providers/portfolio_provider.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:ifind/features/reviews/presentation/providers/review_provider.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/core/services/b2b_service.dart';
import 'package:ifind/core/providers/ai_providers.dart';
import 'package:ifind/core/services/interaction_service.dart';
import 'package:ifind/core/utils/distance_calculator.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ifind/features/reviews/presentation/widgets/add_review_dialog.dart';
import 'package:ifind/features/portfolio/presentation/screens/gallery_media_view_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ifind/features/favourites/presentation/providers/favourites_provider.dart';
import 'package:ifind/features/products/presentation/providers/product_provider.dart';
import 'package:ifind/features/products/domain/entities/product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kGradTop    = Color(0xFF003D2B);
const _kGradMid    = Color(0xFF006241);
const _kGradBottom = Color(0xFF0B7A5A);

final _hasLoggedProfileViewProvider =
    StateProvider.family<bool, String>((ref, businessId) => false);

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class BusinessDetailScreen extends ConsumerWidget {
  final Business business;
  const BusinessDetailScreen({super.key, required this.business});

  // ── Gallery inquiry ────────────────────────────────────────────────────────
  Future<void> _initiateGalleryInquiry(
      BuildContext context, WidgetRef ref, PortfolioItem item) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      AppToast.show(context, 'Please login to inquire', type: ToastType.info);
      return;
    }
    try {
      final ds = ref.read(chatRemoteDataSourceProvider);
      final chat = await ds.getOrCreateChat(
        customerId: user.id,
        businessId: business.id,
      );
      final msg =
          '[MEDIA_INQUIRY]|${item.mediaType.name}|${item.mediaUrl}|Interested in this ${item.mediaType.name}: ${item.caption ?? 'item'}';
      await ds.sendMessage(chatId: chat.id, senderId: user.id, content: msg);
      ref.read(interactionServiceProvider).logInteraction(
            userId: user.id,
            businessId: business.id,
            type: InteractionType.inquirySent,
          );
      if (context.mounted) {
        context.push('/chat', extra: {'chat': chat, 'otherPartyName': business.name});
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(context, friendlyError(e), type: ToastType.error);
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(businessStreamProvider(business.id));
    final currentUser  = ref.watch(currentUserProvider);

    if (currentUser != null && currentUser.id != business.ownerId) {
      final hasLogged = ref.watch(_hasLoggedProfileViewProvider(business.id));
      if (!hasLogged) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(_hasLoggedProfileViewProvider(business.id).notifier).state = true;
          ref.read(interactionServiceProvider).logInteraction(
                userId: currentUser.id,
                businessId: business.id,
                type: InteractionType.profileView,
              );
        });
      }
    }

    return businessAsync.when(
      loading: () => const Scaffold(body: IFindLoadingPage()),
      error:   (e, _) => _ErrorScaffold(business: business),
      data: (reactive) {
        final b = reactive ?? business;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: DefaultTabController(
              length: 3,
              initialIndex: 1,
              child: NestedScrollView(
                headerSliverBuilder: (ctx, _) => [
                  _buildHeroAppBar(ctx, ref, b),
                  _buildStatsStrip(ctx, b),
                  _buildTabBar(ctx),
                ],
                body: TabBarView(
                  children: [
                    _AboutTab(business: b),
                    _PortfolioTab(
                      businessId: b.id,
                      onInquire: (item) => _initiateGalleryInquiry(context, ref, item),
                    ),
                    _ReviewsTab(businessId: b.id),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: _BottomBar(business: b),
          ),
        );
      },
    );
  }

  // ── Hero SliverAppBar ──────────────────────────────────────────────────────
  Widget _buildHeroAppBar(BuildContext context, WidgetRef ref, Business b) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      stretch: true,
      backgroundColor: _kGradTop,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
      actions: [
        Consumer(builder: (ctx, r, _) {
          final saved  = r.watch(favouritesProvider).contains(b.id);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                r.read(favouritesProvider.notifier).toggle(b.id);
                final u = r.read(currentUserProvider);
                if (u != null && !saved) {
                  r.read(interactionServiceProvider).logInteraction(
                        userId: u.id,
                        businessId: b.id,
                        type: InteractionType.savedBusiness,
                      );
                }
                AppToast.show(
                  ctx,
                  saved ? 'Removed from favourites' : 'Saved to favourites',
                  type: saved ? ToastType.info : ToastType.success,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: saved ? Colors.amber : Colors.white,
                  size: 20,
                ),
              ),
            ),
          );
        }),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: _HeroBg(business: b),
      ),
    );
  }

  // ── Stats SliverToBoxAdapter ───────────────────────────────────────────────
  Widget _buildStatsStrip(BuildContext context, Business b) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            _StatPill(
              icon: Icons.star_rounded,
              iconColor: Colors.amber,
              value: b.rating.toStringAsFixed(1),
              label: 'Rating',
            ),
            _kStatDivider,
            _StatPill(
              icon: Icons.rate_review_rounded,
              iconColor: AppColors.primaryGreen,
              value: '${b.reviewCount}',
              label: 'Reviews',
            ),
            _kStatDivider,
            if (b.distance != null)
              _StatPill(
                icon: Icons.near_me_rounded,
                iconColor: Colors.blue,
                value: DistanceCalculator.formatDistance(b.distance!),
                label: 'Away',
              )
            else
              _StatPill(
                icon: b.isVerified
                    ? Icons.verified_rounded
                    : Icons.store_rounded,
                iconColor: b.isVerified ? AppColors.primaryGreen : Colors.grey,
                value: b.isVerified ? 'Verified' : b.category.name,
                label: b.isVerified ? 'Business' : 'Category',
              ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  static const _kStatDivider = VerticalDivider(
    width: 24,
    thickness: 1,
    indent: 6,
    endIndent: 6,
  );

  // ── Tab bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          indicatorColor: AppColors.primaryGreen,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: Colors.grey[400],
          labelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w500, fontSize: 15),
          tabs: const [
            Tab(text: 'About'),
            Tab(text: 'Showcase'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero background widget
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBg extends StatelessWidget {
  final Business business;
  const _HeroBg({required this.business});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Cover image or gradient fallback
        business.coverImageUrl != null
            ? CachedNetworkImage(
                imageUrl: business.coverImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kGradTop, _kGradMid],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => _gradientFallback(),
              )
            : _gradientFallback(),

        // Dark scrim at bottom
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.72),
                ],
                stops: const [0.3, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // Decorative circle
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // ── Bottom content ─────────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // FEATURED / VERIFIED badge
                if (business.isVerified)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium_rounded,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'FEATURED',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms),

                const SizedBox(height: 10),

                // Logo + Name row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Logo
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.white, width: 2.5),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: business.logoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: business.logoUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Center(
                                child: Text(
                                  business.name[0].toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                business.name[0].toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.15),

                const SizedBox(height: 10),

                // Rating + category + location chips row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _HeroChip(
                      icon: Icons.star_rounded,
                      label:
                          '${business.rating.toStringAsFixed(1)} · ${business.reviewCount} reviews',
                      color: Colors.amber,
                    ),
                    _HeroChip(
                      icon: Icons.category_rounded,
                      label: business.category.name,
                      color: Colors.white,
                    ),
                    if (business.address != null)
                      _HeroChip(
                        icon: Icons.location_on_rounded,
                        label: business.address!.length > 28
                            ? '${business.address!.substring(0, 28)}…'
                            : business.address!,
                        color: Colors.white,
                      ),
                  ],
                ).animate().fadeIn(delay: 160.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kGradTop, _kGradMid, _kGradBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero chip
// ─────────────────────────────────────────────────────────────────────────────

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HeroChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat pill
// ─────────────────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TabBar delegate
// ─────────────────────────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  const _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 12;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 12;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 12),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// About tab
// ─────────────────────────────────────────────────────────────────────────────

class _AboutTab extends ConsumerWidget {
  final Business business;
  const _AboutTab({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider(business.id));
    final productsAsync = ref.watch(businessProductsProvider(business.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      children: [
        // About card
        _SectionCard(
          delay: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                  icon: Icons.info_outline_rounded, label: 'About'),
              const SizedBox(height: 12),
              Text(
                business.description,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.darkText.withValues(alpha: 0.8),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Location card
        if (business.address != null)
          _SectionCard(
            delay: 60,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppColors.primaryGreen, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.lightText,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        business.address!,
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText),
                      ),
                    ],
                  ),
                ),
                if (business.phone != null)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse('tel:${business.phone}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.call_rounded,
                          color: Colors.blue, size: 20),
                    ),
                  ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Services / Products section (from portfolio)
        portfolioAsync.when(
          data: (items) {
            final priced = items.where((i) => i.price != null).toList();
            if (priced.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  delay: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(
                          icon: Icons.menu_book_rounded, label: 'Services & Products'),
                      const SizedBox(height: 14),
                      ...priced.asMap().entries.map((e) =>
                          _ServiceRow(item: e.value, index: e.key)),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        // Real products section
        productsAsync.when(
          data: (products) {
            final available = products.where((p) => p.isAvailable).toList();
            if (available.isEmpty) return const SizedBox.shrink();
            return _SectionCard(
              delay: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                      icon: Icons.shopping_bag_outlined, label: 'Products'),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: available.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) =>
                          _ProductCard(product: available[i]),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        // B2B compatibility card (business owners only)
        _B2bCompatibilityCard(targetBusiness: business),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product card (horizontal scroll on About tab)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final price = 'UGX ${product.price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

    return Container(
      width: 130,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: product.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.images.first,
                    width: 130,
                    height: 90,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              price,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 130,
    height: 90,
    color: Colors.grey.shade100,
    child: const Icon(Icons.shopping_bag_outlined,
        color: Colors.grey, size: 32),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Service row
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceRow extends StatelessWidget {
  final PortfolioItem item;
  final int index;
  const _ServiceRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final price = item.price != null
        ? 'UGX ${item.price!.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Thumbnail / icon
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.mediaUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.mediaType == MediaType.video
                        ? (item.thumbnailUrl ?? item.mediaUrl)
                        : item.mediaUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 48,
                      height: 48,
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      child: const Icon(Icons.inventory_2_rounded,
                          color: AppColors.primaryGreen, size: 22),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    child: const Icon(Icons.inventory_2_rounded,
                        color: AppColors.primaryGreen, size: 22),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.caption ?? 'Service',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.darkText,
                  ),
                ),
                if (item.mediaType == MediaType.video)
                  Text(
                    'Video Showcase',
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: AppColors.lightText),
                  ),
              ],
            ),
          ),
          if (price != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.deepGreen],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                price,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 60).ms)
        .slideX(begin: 0.08);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Portfolio / Showcase tab
// ─────────────────────────────────────────────────────────────────────────────

class _PortfolioTab extends ConsumerWidget {
  final String businessId;
  final Function(PortfolioItem) onInquire;
  const _PortfolioTab({required this.businessId, required this.onInquire});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider(businessId));

    return portfolio.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No showcase items yet',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () async => ref.invalidate(portfolioProvider(businessId)),
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _PortfolioCard(item: items[index], onInquire: onInquire, index: index),
          ),
        );
      },
      loading: () => const Center(child: IFindLoaderInline(size: 60)),
      error: (e, _) => ErrorRetryWidget(message: friendlyError(e), slim: true),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final PortfolioItem item;
  final Function(PortfolioItem) onInquire;
  final int index;
  const _PortfolioCard(
      {required this.item, required this.onInquire, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: item.mediaType == MediaType.video
                        ? (item.thumbnailUrl ?? item.mediaUrl)
                        : item.mediaUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade100),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: Icon(
                        item.mediaType == MediaType.video
                            ? Icons.movie_creation_outlined
                            : Icons.image_not_supported_rounded,
                        color: Colors.grey.shade400,
                        size: 36,
                      ),
                    ),
                  ),
                  if (item.mediaType == MediaType.video)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 26),
                      ),
                    ),
                  if (item.price != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen
                                  .withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'UGX ${item.price!.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GalleryMediaViewScreen(
                            item: item,
                            onInquire: () => onInquire(item),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.caption ?? 'Showcase',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        item.mediaType == MediaType.video
                            ? 'Video Showcase'
                            : 'Product Post',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => onInquire(item),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: AppColors.primaryGreen, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 40).ms, duration: 300.ms)
        .scale(begin: const Offset(0.92, 0.92));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reviews tab
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewsTab extends ConsumerWidget {
  final String businessId;
  const _ReviewsTab({required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(businessReviewsProvider(businessId));

    return Column(
      children: [
        // Write review CTA
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGradTop, _kGradMid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AddReviewDialog(businessId: businessId),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.rate_review_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Write a Review',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
        ),

        Expanded(
          child: reviewsAsync.when(
            data: (reviews) {
              if (reviews.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No reviews yet',
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Be the first to share your experience!',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.primaryGreen,
                onRefresh: () async =>
                    ref.refresh(businessReviewsProvider(businessId)),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: reviews.length,
                  itemBuilder: (ctx, i) =>
                      _ReviewCard(review: reviews[i], index: i),
                ),
              );
            },
            loading: () => const Center(child: IFindLoaderInline(size: 60)),
            error: (e, _) =>
                ErrorRetryWidget(message: friendlyError(e), slim: true),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final dynamic review;
  final int index;
  const _ReviewCard({required this.review, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: review.authorAvatarUrl != null
                    ? NetworkImage(review.authorAvatarUrl!) as ImageProvider
                    : null,
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                child: review.authorAvatarUrl == null
                    ? Text(
                        (review.authorName ?? 'A')[0].toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName ?? 'Anonymous',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      timeago.format(review.createdAt),
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: AppColors.lightText),
                    ),
                  ],
                ),
              ),
              // Star rating
              Row(
                children: List.generate(
                  5,
                  (s) => Icon(
                    s < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.darkText.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 50).ms)
        .slideY(begin: 0.08);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom CTA bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  final Business business;
  const _BottomBar({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary row
            Row(
              children: [
                // Post a Need (outlined)
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/post-need'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: const BorderSide(
                            color: AppColors.primaryGreen, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.campaign_rounded, size: 18),
                      label: Text(
                        'Post a Need',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Chat Now (filled gradient)
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryGreen, AppColors.deepGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen
                                .withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final user = ref.read(currentUserProvider);
                          if (user == null) return;
                          try {
                            final chat = await ref
                                .read(chatRemoteDataSourceProvider)
                                .getOrCreateChat(
                                  customerId: user.id,
                                  businessId: business.id,
                                );
                            ref
                                .read(interactionServiceProvider)
                                .logInteraction(
                                  userId: user.id,
                                  businessId: business.id,
                                  type: InteractionType.inquirySent,
                                );
                            if (context.mounted) {
                              context.push('/chat', extra: {
                                'chat': chat,
                                'otherPartyName': business.name,
                              });
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.show(context, friendlyError(e),
                                  type: ToastType.error);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.forum_rounded,
                            color: Colors.white, size: 18),
                        label: Text(
                          'Chat Now',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Secondary row — WhatsApp + Call
            if (business.phone != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SecondaryBtn(
                    icon: Icons.chat_bubble_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () async {
                      final clean =
                          business.phone!.replaceAll(RegExp(r'[^0-9]'), '');
                      final wa =
                          clean.startsWith('256') ? clean : '256$clean';
                      final uri = Uri.parse('https://wa.me/$wa');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  _SecondaryBtn(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    color: Colors.blue,
                    onTap: () async {
                      final uri = Uri.parse('tel:${business.phone}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SecondaryBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  final int delay;
  const _SectionCard({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.08);
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error scaffold
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorScaffold extends ConsumerWidget {
  final Business business;
  const _ErrorScaffold({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 52, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Could not load business',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(businessStreamProvider(business.id)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// B2B Compatibility Card (business owners only)
// ─────────────────────────────────────────────────────────────────────────────

class _B2bCompatibilityCard extends ConsumerWidget {
  final Business targetBusiness;
  const _B2bCompatibilityCard({required this.targetBusiness});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null || currentUser.role != UserRole.businessOwner) {
      return const SizedBox.shrink();
    }

    final myAsync = ref.watch(myBusinessesProvider(currentUser.id));
    return myAsync.when(
      data: (mine) {
        if (mine.isEmpty) return const SizedBox.shrink();
        final my = mine.first;
        if (my.id == targetBusiness.id) return const SizedBox.shrink();

        final compatAsync = ref.watch(
          b2bCompatibilityProvider(
              (myBusiness: my, targetBusiness: targetBusiness)),
        );

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.deepGreen.withValues(alpha: 0.05),
                AppColors.primaryGreen.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.handshake_rounded,
                        color: AppColors.primaryGreen, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'B2B Partnership Score',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.deepGreen,
                        ),
                      ),
                      Text(
                        'AI-powered compatibility',
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: AppColors.lightText),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              compatAsync.when(
                data: (result) => _ScoreDisplay(result: result),
                loading: () => Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Calculating compatibility…',
                        style: GoogleFonts.outfit(
                            color: AppColors.lightText, fontSize: 12)),
                  ],
                ),
                error: (_, __) => Text(
                  'Could not compute score.',
                  style: GoogleFonts.outfit(
                      color: AppColors.lightText, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${my.category.name} ↔ ${targetBusiness.name} (${targetBusiness.category.name})',
                style: GoogleFonts.outfit(
                    fontSize: 11, color: AppColors.lightText),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms);
      },
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  final B2bCompatibilityResult result;
  const _ScoreDisplay({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = result.compatibilityScore;
    final pct   = (score * 100).round();
    final color = score >= 0.75
        ? const Color(0xFF22C55E)
        : score >= 0.50
            ? const Color(0xFFF59E0B)
            : score >= 0.25
                ? const Color(0xFFF97316)
                : const Color(0xFFEF4444);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              result.label,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pct% match',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, color: color, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
