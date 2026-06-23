import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/recommendations/presentation/providers/recommendation_providers.dart';

class AiSearchScreen extends ConsumerWidget {
  const AiSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ── Gradient App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.deepGreen,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.deepGreen, AppColors.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    // Title content
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.auto_awesome,
                                    color: Colors.amber, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI POWERED',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'For You',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Personalized picks, just for you.',
                            style: GoogleFonts.outfit(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body Content ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: user == null
                ? _buildLoginPrompt(context)
                : _buildRecommendations(context, ref, user.id),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            Icon(Icons.person_outline_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Sign in to get personalized recommendations',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(
      BuildContext context, WidgetRef ref, String userId) {
    final recsAsync = ref.watch(
      userRecommendationsProvider(userId: userId, n: 8),
    );
    final featuredAsync = ref.watch(featuredBusinessesProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── B2C Personalized Recommendations ──────────────────────────
          recsAsync.when(
            data: (recs) {
              if (recs.isEmpty) {
                // Cold-start: show featured businesses as fallback
                return _buildFeaturedFallback(context, featuredAsync);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Recommended For You',
                    subtitle:
                        'Based on your activity · ${recs.length} picks',
                    icon: Icons.recommend_rounded,
                  ),
                  const SizedBox(height: 16),
                  ...recs.asMap().entries.map((entry) {
                    return _RecommendationCard(
                      businessId: entry.value.businessId,
                      reasoning: entry.value.aiReasoning,
                      rank: entry.key + 1,
                    )
                        .animate()
                        .fadeIn(delay: (entry.key * 80).ms)
                        .slideY(begin: 0.1);
                  }),
                ],
              );
            },
            loading: () => _buildLoadingState(),
            error: (e, _) => _buildErrorFallback(context, featuredAsync),
          ),

          const SizedBox(height: 32),

          // ── Always show Featured Businesses below ──────────────────────
          _buildSectionHeader(
            'Featured Businesses',
            subtitle: 'Trending in your area',
            icon: Icons.star_rounded,
          ),
          const SizedBox(height: 16),
          featuredAsync.when(
            data: (businesses) {
              if (businesses.isEmpty) {
                return Center(
                  child: Text('No featured businesses',
                      style: GoogleFonts.outfit(color: Colors.grey)),
                );
              }
              return SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: businesses.length,
                  itemBuilder: (ctx, i) => _FeaturedCard(business: businesses[i]),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {String? subtitle, required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepGreen),
            ),
            if (subtitle != null)
              Text(subtitle,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppColors.lightText)),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Recommended For You',
          subtitle: 'Our AI is thinking...',
          icon: Icons.auto_awesome,
        ),
        const SizedBox(height: 24),
        const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Loading your personalized picks...',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFeaturedFallback(
      BuildContext context, AsyncValue<List<Business>> featuredAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Explore more businesses to get personalized recommendations!',
                  style: GoogleFonts.outfit(color: Colors.blue, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildErrorFallback(
      BuildContext context, AsyncValue<List<Business>> featuredAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Personalized recommendations temporarily unavailable. Showing featured businesses.',
                  style: GoogleFonts.outfit(color: Colors.orange, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Recommendation Card ────────────────────────────────────────────────────
class _RecommendationCard extends ConsumerWidget {
  final String businessId;
  final String reasoning;
  final int rank;

  const _RecommendationCard({
    required this.businessId,
    required this.reasoning,
    required this.rank,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(businessProvider(businessId));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: businessAsync.when(
        data: (business) {
          if (business == null) return const SizedBox.shrink();
          return InkWell(
            onTap: () =>
                context.push('/business-details', extra: business),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryGreen, AppColors.deepGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Business logo
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.grey[100],
                      image: business.logoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(business.logoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: business.logoUrl == null
                        ? Icon(Icons.storefront_rounded,
                            color: Colors.grey[400])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Business info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reasoning,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.lightText,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey, size: 20),
                ],
              ),
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

// ── Featured Business Card (horizontal scroll) ─────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final Business business;
  const _FeaturedCard({required this.business});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/business-details', extra: business),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(
                business.coverImageUrl ?? 'https://via.placeholder.com/300'),
            fit: BoxFit.cover,
            onError: (_, __) {},
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(business.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${business.rating} · ${business.category.name}',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
