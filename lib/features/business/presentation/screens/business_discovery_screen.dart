import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/app_drawer.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/core/widgets/owner_avatar.dart';
import 'package:ifind/core/providers/ai_providers.dart';
import 'package:ifind/core/services/interaction_service.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/core/widgets/loading_widget.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/core/utils/distance_calculator.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BusinessDiscoveryScreen extends ConsumerStatefulWidget {
  final BusinessCategory? initialCategory;
  const BusinessDiscoveryScreen({super.key, this.initialCategory});

  @override
  ConsumerState<BusinessDiscoveryScreen> createState() =>
      _BusinessDiscoveryScreenState();
}

class _BusinessDiscoveryScreenState
    extends ConsumerState<BusinessDiscoveryScreen> {
  String _locationLabel = 'Locating...';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedCategoryProvider.notifier).state =
          widget.initialCategory;
      ref.read(searchQueryProvider.notifier).state = '';
      _fetchLocationLabel();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationLabel() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationLabel = 'Kampala (default)');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
      if (mounted) {
        setState(() => _locationLabel =
            '${pos.latitude.toStringAsFixed(4)}°N, ${pos.longitude.toStringAsFixed(4)}°E');
      }
    } catch (_) {
      if (mounted) setState(() => _locationLabel = 'Kampala (default)');
    }
  }

  void _showRadiusSheet() {
    final currentRadius = ref.read(searchRadiusProvider);
    double tempRadius = currentRadius;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded,
                        color: AppColors.primaryGreen),
                    const SizedBox(width: 10),
                    Text('Search Radius',
                        style: GoogleFonts.outfit(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _locationLabel,
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Radius',
                        style: GoogleFonts.outfit(
                            fontSize: 14, color: Colors.grey.shade600)),
                    Text(
                      '${tempRadius.toStringAsFixed(0)} km',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: tempRadius,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  activeColor: AppColors.primaryGreen,
                  inactiveColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                  onChanged: (v) => setModalState(() => tempRadius = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 km',
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: Colors.grey)),
                    Text('50 km',
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(searchRadiusProvider.notifier).state =
                          tempRadius;
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Apply',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessesState = ref.watch(filteredBusinessesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final radius = ref.watch(searchRadiusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(nearbyBusinessesProvider.notifier).loadBusinesses();
          _fetchLocationLabel();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context, ref, radius),
            _buildCategorySection(ref, selectedCategory),
            _buildNearMeHeader(context, businessesState),
            _buildBusinessList(businessesState),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, double radius) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 180,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          tooltip: 'Menu',
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF003D2B), Color(0xFF006241), Color(0xFF0B7A5A)],
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => ref
                                .read(searchQueryProvider.notifier)
                                .state = value,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              hintText: 'Search shops or products...',
                              hintStyle: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 16,
                              ),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: Colors.white),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close_rounded,
                                          color: Colors.white),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(
                                                searchQueryProvider.notifier)
                                            .state = '';
                                        setState(() {});
                                      },
                                    ),
                            ),
                            onTapOutside: (_) =>
                                FocusScope.of(context).unfocus(),
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
              tooltip: 'Search radius: ${radius.toStringAsFixed(0)} km',
              icon: const Icon(Icons.location_on_rounded, color: Colors.white),
              onPressed: _showRadiusSheet,
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

  Widget _buildNearMeHeader(
      BuildContext context, AsyncValue<List<Business>> businessesState) {
    final count = businessesState.valueOrNull?.length ?? 0;
    final radius = ref.watch(searchRadiusProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  '$count found · within ${radius.toStringAsFixed(0)} km',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppColors.lightText),
                ),
              ],
            ),
            GestureDetector(
              onTap: _showRadiusSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune_rounded,
                        size: 14, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      'Radius',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
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

  Widget _buildBusinessList(AsyncValue<List<Business>> state) {
    return state.when(
      data: (businesses) {
        if (businesses.isEmpty) {
          return const SliverFillRemaining(
            child: EmptyStateWidget(
              title: 'Nothing found',
              message: 'Try a different category or increase the search radius.',
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
          SliverFillRemaining(child: ErrorRetryWidget(message: friendlyError(e))),
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
          shadowColor: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.4)
              : Colors.black12,
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
                    : Border.all(
                        color: AppColors.divider.withValues(alpha: 0.5)),
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

class _BusinessGridTile extends ConsumerWidget {
  final Business business;
  const _BusinessGridTile({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamedBusiness =
        ref.watch(businessStreamProvider(business.id)).valueOrNull;
    final liveBusiness = streamedBusiness == null
        ? business
        : streamedBusiness.copyWith(
            distance: streamedBusiness.distance ?? business.distance);

    return GestureDetector(
      onTap: () {
        // Log search_click interaction
        final user = ref.read(currentUserProvider);
        if (user != null) {
          ref.read(interactionServiceProvider).logInteraction(
                userId: user.id,
                businessId: liveBusiness.id,
                type: InteractionType.searchClick,
              );
        }
        context.push('/business-details', extra: liveBusiness);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
                        image: liveBusiness.logoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(liveBusiness.logoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color:
                            AppColors.primaryGreen.withValues(alpha: 0.1),
                      ),
                      alignment: Alignment.center,
                      child: liveBusiness.logoUrl == null
                          ? Text(
                              liveBusiness.name.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            )
                          : null,
                    ),
                    if (liveBusiness.isVerified)
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
                    Positioned(
                      bottom: -6,
                      right: -6,
                      child: OwnerAvatar(
                        ownerId: liveBusiness.ownerId,
                        radius: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      liveBusiness.name,
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
                      liveBusiness.description,
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
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          liveBusiness.rating.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    if (liveBusiness.distance != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          DistanceCalculator.formatDistance(
                              liveBusiness.distance!),
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
