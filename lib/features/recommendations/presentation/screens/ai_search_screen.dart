import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/distance_calculator.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/recommendations/presentation/providers/recommendation_providers.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';

class AiSearchScreen extends ConsumerWidget {
  const AiSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF003D2B),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF003D2B), Color(0xFF006241), Color(0xFF0B7A5A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
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
                            'Personalized picks based on your activity.',
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
    final nearbyAsync = ref.watch(nearbyBusinessesProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── AI Personalized Recommendations ───────────────────────────
          recsAsync.when(
            data: (recs) {
              if (recs.isEmpty) {
                return _buildColdStartSection(context, featuredAsync);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Recommended For You',
                    subtitle: 'Based on your activity · ${recs.length} picks',
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
            error: (e, _) => _buildColdStartSection(context, featuredAsync),
          ),

          const SizedBox(height: 32),

          // ── Hybrid: Nearby + Personalized ─────────────────────────────
          nearbyAsync.when(
            data: (nearbyList) {
              recsAsync.whenData((recs) {});
              final recIds = recsAsync.valueOrNull
                      ?.map((r) => r.businessId)
                      .toSet() ??
                  {};

              // Businesses that are BOTH nearby AND recommended = highest relevance
              final hybridPicks = nearbyList
                  .where((b) => recIds.contains(b.id))
                  .take(6)
                  .toList();

              if (hybridPicks.isEmpty) {
                // Fall back to just nearby businesses as a section
                final nearby = nearbyList.take(6).toList();
                if (nearby.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Nearby Businesses',
                      subtitle: 'Shops close to you',
                      icon: Icons.location_on_rounded,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: nearby.length,
                        itemBuilder: (ctx, i) =>
                            _NearbyCard(business: nearby[i]),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Nearby & Recommended',
                    subtitle:
                        'Personalized picks close to you · ${hybridPicks.length} found',
                    icon: Icons.my_location_rounded,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: hybridPicks.length,
                      itemBuilder: (ctx, i) =>
                          _NearbyCard(business: hybridPicks[i]),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 32),

          // ── Featured Businesses ────────────────────────────────────────
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
                  itemBuilder: (ctx, i) =>
                      _FeaturedCard(business: businesses[i]),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: IFindLoaderInline(size: 70)),
            ),
            error: (e, _) => const SizedBox.shrink(),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 96),
        ],
      ),
    );
  }

  // Cold start: show featured businesses with an explanation banner
  Widget _buildColdStartSection(
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
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Explore more businesses to unlock your personalised recommendations!',
                  style: GoogleFonts.outfit(color: Colors.blue, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Popular Near You',
          subtitle: 'Top rated businesses to get you started',
          icon: Icons.local_fire_department_rounded,
        ),
        const SizedBox(height: 16),
        featuredAsync.when(
          data: (businesses) {
            if (businesses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No businesses found.',
                      style: GoogleFonts.outfit(color: Colors.grey)),
                ),
              );
            }
            return Column(
              children: businesses
                  .take(6)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) => _FeaturedListCard(business: entry.value)
                      .animate()
                      .fadeIn(delay: (entry.key * 60).ms)
                      .slideY(begin: 0.1))
                  .toList(),
            );
          },
          loading: () => const Center(child: IFindLoaderInline(size: 60)),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
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
        const IFindLoaderInline(size: 80, label: 'Personalising picks…'),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── AI Recommendation Card (ranked list) ──────────────────────────────────────
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
            onTap: () => context.push('/business-details', extra: business),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
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
                        if (business.distance != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 12,
                                  color: AppColors.primaryGreen
                                      .withValues(alpha: 0.8)),
                              const SizedBox(width: 2),
                              Text(
                                DistanceCalculator.formatDistance(
                                    business.distance!),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
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

// ── Nearby card (horizontal scroll) ───────────────────────────────────────────
class _NearbyCard extends StatelessWidget {
  final Business business;
  const _NearbyCard({required this.business});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/business-details', extra: business),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  image: business.logoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(business.logoUrl!),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: business.logoUrl == null
                    ? Text(
                        business.name.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        business.rating.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      if (business.distance != null)
                        Text(
                          DistanceCalculator.formatDistance(business.distance!),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Featured card (horizontal scroll) ─────────────────────────────────────────
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
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          image: business.coverImageUrl != null
              ? DecorationImage(
                  image: NetworkImage(business.coverImageUrl!),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
              : null,
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
                  '${business.rating.toStringAsFixed(1)} · ${business.category.name}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Featured list card (cold-start vertical list) ──────────────────────────────
class _FeaturedListCard extends StatelessWidget {
  final Business business;
  const _FeaturedListCard({required this.business});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/business-details', extra: business),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                image: business.logoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(business.logoUrl!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: business.logoUrl == null
                  ? Text(
                      business.name.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
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
                    business.category.name,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.lightText),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        business.rating.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      if (business.distance != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.location_on_rounded,
                            size: 12,
                            color:
                                AppColors.primaryGreen.withValues(alpha: 0.8)),
                        const SizedBox(width: 2),
                        Text(
                          DistanceCalculator.formatDistance(business.distance!),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
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
  }
}
