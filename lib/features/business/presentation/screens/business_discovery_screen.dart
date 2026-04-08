import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/presentation/screens/business_details_screen.dart';
import 'package:ifind/core/widgets/loading_widget.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BusinessDiscoveryScreen extends ConsumerWidget {
  final BusinessCategory? initialCategory;
  const BusinessDiscoveryScreen({super.key, this.initialCategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Set initial category if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (initialCategory != null &&
          ref.read(selectedCategoryProvider) == null) {
        ref.read(selectedCategoryProvider.notifier).state = initialCategory;
      }
    });

    final businessesState = ref.watch(nearbyBusinessesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(nearbyBusinessesProvider.notifier).loadBusinesses();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context, ref),
            _buildCategorySection(ref, selectedCategory),
            _buildNearMeHeader(),
            _buildBusinessList(businessesState),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 180,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.deepGreen, AppColors.primaryGreen],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover Businesses',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => showSearch(
                        context: context,
                        delegate: BusinessSearchDelegate(ref),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, color: Colors.white),
                                const SizedBox(width: 12),
                                Text(
                                  'Search shops or products...',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: IconButton(
              icon: const Icon(Icons.location_on_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
      WidgetRef ref, BusinessCategory? selectedCategory) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              'Categories',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: BusinessCategory.values.length + 1,
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final category =
                    isAll ? null : BusinessCategory.values[index - 1];
                final isSelected = selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _CategoryBall(
                    label: isAll ? 'All' : category!.name,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state =
                          category;
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildNearMeHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nearby Shops',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            Text(
              'See All',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessList(AsyncValue<List<Business>> state) {
    return state.when(
      data: (businesses) {
        if (businesses.isEmpty) {
          return const SliverFillRemaining(
            child: EmptyStateWidget(
              title: 'Nothing found',
              message: 'Try a different category or broader search.',
              icon: Icons.search_off_rounded,
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _BusinessGridTile(business: businesses[index])
                    .animate()
                    .fadeIn(delay: (index * 30).ms, duration: 300.ms)
                    .scale(begin: const Offset(0.9, 0.9));
              },
              childCount: businesses.length,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(child: LoadingWidget()),
      error: (e, s) =>
          SliverFillRemaining(child: Center(child: Text('Error: $e'))),
    );
  }
}

class _CategoryBall extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryBall({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          elevation: isSelected ? 8 : 2,
          shadowColor: isSelected ? AppColors.primaryGreen.withValues(alpha: 0.4) : Colors.black12,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: isSelected 
                  ? null 
                  : Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
              ),
              child: Icon(
                _getCategoryIcon(label),
                size: 30,
                color: isSelected ? Colors.white : AppColors.primaryGreen,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 72,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primaryGreen : AppColors.darkText,
            ),
          ),
        ),
      ],
    );
  }
}

class _BusinessGridTile extends StatelessWidget {
  final Business business;
  const _BusinessGridTile({required this.business});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BusinessDetailScreen(business: business)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: business.logoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(business.logoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      ),
                      alignment: Alignment.center,
                      child: business.logoUrl == null
                        ? Text(
                            business.name.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          )
                        : null,
                    ),
                    if (business.isVerified)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: AppColors.primaryGreen,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      business.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.darkText,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      business.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: AppColors.darkText.withValues(alpha: 0.6),
                        height: 1.1,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          business.rating.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    if (business.distance != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${business.distance!.toStringAsFixed(1)}km',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

class BusinessSearchDelegate extends SearchDelegate {
  final WidgetRef ref;
  BusinessSearchDelegate(this.ref);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme:
          const AppBarTheme(backgroundColor: Colors.white, elevation: 0),
      inputDecorationTheme:
          const InputDecorationTheme(border: InputBorder.none),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
            icon: const Icon(Icons.close_rounded), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = query;
      close(context, null);
    });
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) => Container(
        color: Colors.white,
        child: Center(
          child: Text('Search businesses or items...',
              style: GoogleFonts.outfit(color: Colors.grey)),
        ),
      );
}

IconData _getCategoryIcon(String label) {
  switch (label.toLowerCase()) {
    case 'all':
      return Icons.grid_view_rounded;
    case 'retail':
      return Icons.shopping_bag_rounded;
    case 'service':
      return Icons.build_rounded;
    case 'food':
      return Icons.restaurant_rounded;
    case 'fashion':
      return Icons.checkroom_rounded;
    case 'electronics':
      return Icons.devices_rounded;
    case 'home':
      return Icons.home_rounded;
    case 'beauty':
      return Icons.face_retouching_natural_rounded;
    case 'automotive':
      return Icons.directions_car_rounded;
    case 'health':
      return Icons.medical_services_rounded;
    case 'sports':
      return Icons.sports_basketball_rounded;
    case 'kids':
      return Icons.child_care_rounded;
    case 'education':
      return Icons.school_rounded;
    case 'entertainment':
      return Icons.movie_rounded;
    case 'arcade':
      return Icons.games_rounded;
    case 'travel':
      return Icons.flight_rounded;
    case 'realestate':
      return Icons.apartment_rounded;
    case 'pets':
      return Icons.pets_rounded;
    case 'finance':
      return Icons.account_balance_rounded;
    default:
      return Icons.category_rounded;
  }
}
