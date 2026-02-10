import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/portfolio/presentation/providers/portfolio_provider.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:ifind/features/reviews/presentation/providers/review_provider.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

class BusinessDetailScreen extends ConsumerWidget {
  final Business business;

  const BusinessDetailScreen({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: AppColors.deepGreen,
                flexibleSpace: FlexibleSpaceBar(
                  background: business.coverImageUrl != null
                      ? Image.network(business.coverImageUrl!, fit: BoxFit.cover)
                      : Container(color: AppColors.primaryGreen),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    labelColor: AppColors.primaryGreen,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primaryGreen,
                    tabs: [
                      Tab(text: 'About'),
                      Tab(text: 'Gallery'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _AboutTab(business: business),
              _PortfolioTab(businessId: business.id),
              _ReviewsTab(businessId: business.id),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                onPressed: () async {
                  if (business.phone != null) {
                    final cleanPhone = business.phone!.replaceAll(RegExp(r'[^0-9]'), '');
                    final whatsappPhone = cleanPhone.startsWith('256') ? cleanPhone : '256$cleanPhone';
                    final uri = Uri.parse('https://wa.me/$whatsappPhone');
                    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline),
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final user = ref.read(currentUserProvider);
                    if (user == null) return;
                    
                    final chatData = await ref.read(chatRemoteDataSourceProvider).getOrCreateChat(
                      customerId: user.id,
                      businessId: business.id,
                    );
                    
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            chat: Chat(
                              id: chatData['id'],
                              customerId: chatData['customer_id'],
                              businessId: chatData['business_id'],
                              createdAt: DateTime.parse(chatData['created_at']),
                            ),
                            otherPartyName: business.name,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.message_rounded),
                  label: const Text('Message'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (business.phone != null) {
                      final uri = Uri.parse('tel:${business.phone}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Call'),
                ),
              ),
            ],
          ),
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
          Text(
            business.name,
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text('${business.rating} (${business.reviewCount} reviews)', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Text('About', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(business.description, style: const TextStyle(height: 1.5, color: Colors.black87)),
          const SizedBox(height: 24),
          Text('Location', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primaryGreen),
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
  const _PortfolioTab({required this.businessId});

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
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item.mediaType == MediaType.video 
                            ? (item.thumbnailUrl ?? item.mediaUrl)
                            : item.mediaUrl,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                          ),
                        ),
                      ),
                      if (item.mediaType == MediaType.video)
                        const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48)),
                      
                      // Caption overlay
                      if (item.caption != null && item.caption!.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Text(
                              item.caption!,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No reviews yet', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
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
                          backgroundImage: review.authorAvatarUrl != null ? NetworkImage(review.authorAvatarUrl!) : null,
                          backgroundColor: Colors.grey[200],
                          child: review.authorAvatarUrl == null ? const Icon(Icons.person, size: 16, color: Colors.grey) : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review.authorName ?? 'Anonymous',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      timeago.format(review.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (starIndex) {
                    return Icon(
                      starIndex < review.rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                ),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    review.comment!,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
