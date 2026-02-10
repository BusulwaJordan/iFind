import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/presentation/screens/business_details_screen.dart';
import 'package:ifind/core/widgets/loading_widget.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BusinessDiscoveryScreen extends ConsumerWidget {
  const BusinessDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesState = ref.watch(nearbyBusinessesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Discover Local',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryGreen.withValues(alpha: 0.05),
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              _SearchButton(),
              IconButton(
                icon: const Icon(Icons.filter_list, color: AppColors.darkText),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filters coming soon!')),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: BusinessCategory.values.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: 'All',
                        isSelected: selectedCategory == null,
                        onSelected: (selected) {
                          ref.read(selectedCategoryProvider.notifier).state = null;
                        },
                      ),
                    );
                  }
                  final category = BusinessCategory.values[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryChip(
                      label: category.name.toUpperCase(),
                      isSelected: selectedCategory == category,
                      onSelected: (selected) {
                        ref.read(selectedCategoryProvider.notifier).state = 
                            selected ? category : null;
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          
          businessesState.when(
            data: (businesses) {
              if (businesses.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyStateWidget(
                    title: 'No shops found nearby',
                    message: 'Try scanning a different category or arcade to see what\'s available.',
                    icon: Icons.store_mall_directory_outlined,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final business = businesses[index];
                      return BusinessCard(business: business)
                        .animate()
                        .fadeIn(delay: (index * 100).ms)
                        .slideY(begin: 0.1);
                    },
                    childCount: businesses.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: LoadingWidget(),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Text('Error: $error'), // Should not be reached due to fallback
              ),
            ),
          ),
        ],
      ),
    );
  }
} // End of BusinessDiscoveryScreen

// Helper widgets and classes follow below


class _SearchButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.search, color: AppColors.darkText),
      onPressed: () {
        showSearch(
          context: context,
          delegate: BusinessSearchDelegate(ref),
        );
      },
    );
  }
}

class BusinessSearchDelegate extends SearchDelegate {
  final WidgetRef ref;

  BusinessSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          ref.read(searchQueryProvider.notifier).state = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Update provider and close search to show results in main screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = query;
      close(context, null);
    });
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Search for businesses...'));
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.darkText,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: AppColors.primaryGreen,
      checkmarkColor: Colors.white,
      elevation: 0,
      pressElevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primaryGreen : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class BusinessCard extends StatelessWidget {
  final Business business;

  const BusinessCard({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessDetailScreen(business: business),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Cover Image Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: business.coverImageUrl != null
                        ? Image.network(
                            business.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.lightGreen.withValues(alpha: 0.2),
                              child: const Icon(Icons.store, size: 48, color: AppColors.primaryGreen),
                            ),
                          )
                        : Container(
                            color: AppColors.lightGreen.withValues(alpha: 0.2),
                            child: const Center(
                              child: Icon(Icons.store, size: 48, color: AppColors.primaryGreen),
                            ),
                          ),
                  ),
                ),
                if (business.isVerified)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Rating Badge
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          business.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${business.reviewCount})',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          business.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    business.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.lightText,
                          height: 1.4,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primaryGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          business.address ?? 'No address',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (business.distance != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${business.distance!.toStringAsFixed(1)} km',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
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
