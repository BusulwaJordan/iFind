import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';

const _kGradTop = Color(0xFF003D2B);
const _kGradMid = Color(0xFF006241);
const _kGradBot = Color(0xFF0B7A5A);

class ShopProfileScreen extends ConsumerWidget {
  const ShopProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: IFindLoadingPage());
    }

    final businessesAsync = ref.watch(myBusinessesStreamProvider(user.id));

    return businessesAsync.when(
      loading: () => const Scaffold(body: IFindLoadingPage()),
      error: (e, _) => _ErrorScaffold(message: e.toString()),
      data: (businesses) {
        if (businesses.isEmpty) {
          return _NoShopScaffold(onSetUp: () => context.go('/setup-shop'));
        }
        return _ShopProfileView(business: businesses.first);
      },
    );
  }
}

// ── No shop state ─────────────────────────────────────────────────────────────

class _NoShopScaffold extends StatelessWidget {
  final VoidCallback onSetUp;
  const _NoShopScaffold({required this.onSetUp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kGradTop, _kGradMid, _kGradBot],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                title: Text('My Shop Profile',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              const Icon(Icons.storefront_rounded,
                  size: 72, color: Colors.white54),
              const SizedBox(height: 24),
              Text('No shop set up yet',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Set up your shop profile to start receiving customers.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ElevatedButton.icon(
                  onPressed: onSetUp,
                  icon: const Icon(Icons.add_business_rounded),
                  label: Text('Set Up My Shop',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Main profile view ─────────────────────────────────────────────────────────

class _ShopProfileView extends StatelessWidget {
  final Business business;
  const _ShopProfileView({required this.business});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeroAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(context),
                  const SizedBox(height: 16),
                  _buildContactCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildHeroAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: _kGradTop,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image or gradient
            business.coverImageUrl != null
                ? Image.network(business.coverImageUrl!, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kGradTop, _kGradMid, _kGradBot],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
            // Dark scrim
            Container(color: Colors.black.withValues(alpha: 0.45)),
            // Bottom content
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Logo
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2.5),
                          color: Colors.white.withValues(alpha: 0.15),
                          image: business.logoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(business.logoUrl!),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: business.logoUrl == null
                            ? const Icon(Icons.storefront_rounded,
                                color: Colors.white70, size: 30)
                            : null,
                      ).animate().scale(
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(width: 12),
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (business.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded,
                                      color: Colors.lightBlueAccent, size: 18),
                                ],
                              ],
                            ).animate().fadeIn(delay: 100.ms),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _HeroChip(
                                  icon: Icons.category_rounded,
                                  label: _formatCategory(business.category),
                                ),
                                if (business.reviewCount > 0) ...[
                                  const SizedBox(width: 6),
                                  _HeroChip(
                                    icon: Icons.star_rounded,
                                    label:
                                        '${business.rating.toStringAsFixed(1)} (${business.reviewCount})',
                                    iconColor: Colors.amber,
                                  ),
                                ],
                              ],
                            ).animate().fadeIn(delay: 200.ms),
                          ],
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

  Widget _buildInfoCard(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'About', icon: Icons.info_outline_rounded),
          const SizedBox(height: 10),
          Text(
            business.description.isEmpty
                ? 'No description provided.'
                : business.description,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.75),
              height: 1.55,
            ),
          ),
          if (business.address != null && business.address!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 16,
                    color: AppColors.primaryGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    business.address!,
                    style: GoogleFonts.outfit(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, duration: 400.ms);
  }

  Widget _buildContactCard(BuildContext context) {
    final items = <_ContactRow>[];
    if (business.phone != null && business.phone!.isNotEmpty) {
      items.add(_ContactRow(
          icon: Icons.phone_rounded,
          label: 'Phone',
          value: business.phone!));
    }
    if (business.email != null && business.email!.isNotEmpty) {
      items.add(_ContactRow(
          icon: Icons.email_rounded,
          label: 'Email',
          value: business.email!));
    }
    if (business.website != null && business.website!.isNotEmpty) {
      items.add(_ContactRow(
          icon: Icons.language_rounded,
          label: 'Website',
          value: business.website!));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
              title: 'Contact', icon: Icons.contact_phone_rounded),
          const SizedBox(height: 10),
          ...items.map((row) => _buildContactRow(context, row)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, duration: 400.ms);
  }

  Widget _buildContactRow(BuildContext context, _ContactRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(row.icon, size: 16, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.label,
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5))),
              Text(row.value,
                  style:
                      GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryGreen, AppColors.deepGreen],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => context.push('/create-business',
              extra: {'business': business}),
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: Text('Edit Shop Details',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5, duration: 350.ms);
  }

  String _formatCategory(BusinessCategory cat) {
    final raw = cat.name;
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _ContactRow {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow(
      {required this.icon, required this.label, required this.value});
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _HeroChip({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor ?? Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style:
                  GoogleFonts.outfit(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen)),
      ],
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  const _ErrorScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kGradTop,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('My Shop Profile',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Text('Error: $message',
            style: GoogleFonts.outfit(color: Colors.red)),
      ),
    );
  }
}
