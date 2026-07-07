import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:ifind/core/utils/distance_calculator.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/favourites/presentation/providers/favourites_provider.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedBusinessesProvider);
    final favouritesAsync = ref.watch(favouritesProvider);
    final savedIds = favouritesAsync.valueOrNull ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(36)),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 14, 20, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF003D2B),
                      Color(0xFF006241),
                      Color(0xFF0B7A5A)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.bookmark_rounded,
                                color: Colors.amber, size: 22),
                            const SizedBox(width: 8),
                            Text('Favourites',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 16),
                        Text(
                          '${savedIds.length} saved business${savedIds.length == 1 ? '' : 'es'}',
                          style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 14),
                        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (favouritesAsync.isLoading)
            const SliverFillRemaining(child: IFindLoaderInline())
          else if (savedIds.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border_rounded,
                        size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 20),
                    Text(
                      'No saved businesses yet',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the bookmark icon on any\nbusiness to save it here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/discover'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.explore_rounded),
                      label: Text('Browse Businesses',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          else
            savedAsync.when(
              data: (businesses) => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _SavedBusinessCard(
                      business: businesses[i],
                      onRemove: () => ref
                          .read(favouritesProvider.notifier)
                          .toggle(businesses[i].id),
                    )
                        .animate()
                        .fadeIn(delay: (i * 60).ms)
                        .slideX(begin: 0.1),
                    childCount: businesses.length,
                  ),
                ),
              ),
              loading: () => const SliverFillRemaining(child: IFindLoaderInline()),
              error: (e, _) => SliverFillRemaining(
                child: ErrorRetryWidget(message: friendlyError(e)),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _SavedBusinessCard extends StatelessWidget {
  final Business business;
  final Future<bool> Function() onRemove;

  const _SavedBusinessCard({required this.business, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/business-details', extra: business),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
                          fontSize: 24,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            business.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.darkText,
                            ),
                          ),
                        ),
                        if (business.isVerified)
                          const Icon(Icons.verified_rounded,
                              color: AppColors.primaryGreen, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business.category.name,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.lightText),
                    ),
                    const SizedBox(height: 6),
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
                              color: AppColors.darkText),
                        ),
                        const SizedBox(width: 8),
                        if (business.distance != null) ...[
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
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final ok = await onRemove();
                  if (!context.mounted) return;
                  AppToast.show(
                    context,
                    ok
                        ? '${business.name} removed from favourites'
                        : 'Could not remove — try again',
                    type: ok ? ToastType.info : ToastType.error,
                  );
                },
                icon: const Icon(Icons.bookmark_remove_rounded,
                    color: Colors.redAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
