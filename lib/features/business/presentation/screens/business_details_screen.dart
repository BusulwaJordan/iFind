import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/portfolio/presentation/providers/portfolio_provider.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:ifind/features/reviews/presentation/providers/review_provider.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ifind/features/reviews/presentation/widgets/add_review_dialog.dart';
import 'package:ifind/features/portfolio/presentation/screens/gallery_media_view_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

class BusinessDetailScreen extends ConsumerWidget {
  final Business business;

  const BusinessDetailScreen({super.key, required this.business});

  Future<void> _initiateGalleryInquiry(
      BuildContext context, WidgetRef ref, PortfolioItem item) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to inquire')));
      return;
    }

    try {
      final chatDataSource = ref.read(chatRemoteDataSourceProvider);
      final chat = await chatDataSource.getOrCreateChat(
        customerId: user.id,
        businessId: business.id,
      );

      // Send inquiry message automatically
      final inquiryMessage =
          '[MEDIA_INQUIRY]|${item.mediaType.name}|${item.mediaUrl}|Interested in this ${item.mediaType.name}: ${item.caption ?? 'item'}';
      await chatDataSource.sendMessage(
        chatId: chat.id,
        senderId: user.id,
        content: inquiryMessage,
      );

      if (context.mounted) {
        context.push('/chat', extra: {
          'chat': chat,
          'otherPartyName': business.name,
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(businessProvider(business.id));

    return businessAsync.when(
      data: (reactiveBusiness) {
        final displayBusiness = reactiveBusiness ?? business;
        return Scaffold(
          body: DefaultTabController(
            length: 3,
            initialIndex: 1, // Set 'Showcase' as the default landing tab
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    stretch: true,
                    backgroundColor: AppColors.deepGreen,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                      onPressed: () => context.pop(),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          displayBusiness.coverImageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: displayBusiness.coverImageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.deepGreen,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.white70),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(color: AppColors.primaryGreen),
                                )
                              : Container(color: AppColors.primaryGreen),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 60,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (displayBusiness.isVerified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.verified_rounded,
                                            color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'VERIFIED BUSINESS',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  displayBusiness.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        indicatorColor: AppColors.primaryGreen,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorWeight: 3,
                        labelColor: AppColors.primaryGreen,
                        unselectedLabelColor: Colors.grey[400],
                        labelStyle: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        unselectedLabelStyle: GoogleFonts.outfit(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        tabs: const [
                          Tab(text: 'Discovery'),
                          Tab(text: 'Showcase'),
                          Tab(text: 'Reviews'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: Container(
                color: const Color(0xFFF8FAFB),
                child: TabBarView(
                  children: [
                    _AboutTab(business: displayBusiness),
                    _PortfolioTab(
                      businessId: displayBusiness.id,
                      onInquire: (item) =>
                          _initiateGalleryInquiry(context, ref, item),
                    ),
                    _ReviewsTab(businessId: displayBusiness.id),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomBar(context, ref, displayBusiness),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, WidgetRef ref, Business business) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: () async {
                  if (business.phone != null) {
                    final cleanPhone =
                        business.phone!.replaceAll(RegExp(r'[^0-9]'), '');
                    final whatsappPhone = cleanPhone.startsWith('256')
                        ? cleanPhone
                        : '256$cleanPhone';
                    final uri = Uri.parse('https://wa.me/$whatsappPhone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  }
                },
                icon: const Icon(Icons.chat_bubble_rounded,
                    color: Color(0xFF25D366), size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = ref.read(currentUserProvider);
                    if (user == null) return;
                    final chat = await ref
                        .read(chatRemoteDataSourceProvider)
                        .getOrCreateChat(
                          customerId: user.id,
                          businessId: business.id,
                        );
                    if (context.mounted) {
                      context.push('/chat', extra: {
                        'chat': chat,
                        'otherPartyName': business.name,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.primaryGreen.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.forum_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('INBOX',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: () async {
                  if (business.phone != null) {
                    final uri = Uri.parse('tel:${business.phone}');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  }
                },
                icon: const Icon(Icons.call_rounded,
                    color: Colors.blue, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTab extends ConsumerWidget {
  final Business business;
  const _AboutTab({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        // Just a refresh gesture - actual data will reload on navigation back
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              if (business.logoUrl != null) ...[
                SizedBox(
                  height: 60,
                  width: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: business.logoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.storefront),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: GoogleFonts.outfit(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${business.rating} (${business.reviewCount} reviews)',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('About',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(business.description,
              style: const TextStyle(height: 1.5, color: Colors.black87)),
          const SizedBox(height: 24),
          Text('Location',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Expanded(child: Text(business.address ?? 'No address provided')),
            ],
          ),
        ],
      ),
    );
  }
}

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
          return const Center(child: Text('No portfolio items yet'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(portfolioProvider(businessId));
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
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
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: item.mediaType == MediaType.video
                                  ? (item.thumbnailUrl ?? item.mediaUrl)
                                  : item.mediaUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    item.mediaType == MediaType.video
                                        ? Icons.movie_creation_outlined
                                        : Icons.image_not_supported_rounded,
                                    color: Colors.grey[400],
                                    size: 48,
                                  ),
                                ),
                              ),
                              memCacheHeight: 280,
                              memCacheWidth: 280,
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
                                      color: Colors.white, size: 28),
                                ),
                              ),

                            // High-End Bold Price Tag
                            if (item.price != null)
                              Positioned(
                                top: 10,
                                left: 10,
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
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'UGX ${item.price!.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),

                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // For now keep MaterialPageRoute for the gallery view since it's a detail
                                  // BUT we can use it via path if we defined it.
                                  // Let's use context.push if we want but this is fine for deep detail.
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GalleryMediaViewScreen(
                                        item: item,
                                        onInquire: () => onInquire(item),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.caption ?? 'Product Story',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.mediaType == MediaType.video
                                ? 'Video Showcase'
                                : 'Product Post',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 16),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _ReviewsTab extends ConsumerWidget {
  final String businessId;
  const _ReviewsTab({required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(businessReviewsProvider(businessId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => showDialog(
                context: context,
                builder: (_) => AddReviewDialog(businessId: businessId)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
              foregroundColor: AppColors.primaryGreen,
              elevation: 0,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Write a Review',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
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
                          size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('No reviews yet. Be the first to rate!',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.refresh(businessReviewsProvider(businessId)),
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const Divider(height: 32),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: review.authorAvatarUrl !=
                                          null
                                      ? NetworkImage(review.authorAvatarUrl!)
                                      : null,
                                  backgroundColor: Colors.grey[200],
                                  child: review.authorAvatarUrl == null
                                      ? const Icon(Icons.person,
                                          size: 16, color: Colors.grey)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  review.authorName ?? 'Anonymous',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              timeago.format(review.createdAt),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            );
                          }),
                        ),
                        if (review.comment != null &&
                            review.comment!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            review.comment!,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}
