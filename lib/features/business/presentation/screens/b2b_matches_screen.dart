import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/b2b_provider.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';

// Dark green constant matching your dashboard
const _darkGreen = Color(0xFF0A5C36);

class B2bMatchesScreen extends ConsumerWidget {
  const B2bMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final myBusinessesAsync = ref.watch(myBusinessesProvider(user?.id ?? ''));
    final business = myBusinessesAsync.value?.firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF5EA), // Light green background
      appBar: AppBar(
        title: Text(
          'B2B Matches',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: _darkGreen,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: myBusinessesAsync.when(
        data: (businesses) {
          if (businesses.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Business Found',
              message: 'You need to create a business to see B2B matches.',
              icon: Icons.business_center_outlined,
            );
          }

          if (business == null) {
            return const Center(child: Text('No business linked to your account.'));
          }

          final candidatesAsync = ref.watch(b2bPartnerCandidatesProvider(business));

          return candidatesAsync.when(
            data: (candidates) {
              if (candidates.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No B2B Matches Yet',
                  message: 'We\'ll suggest potential partners as more businesses join the platform.',
                  icon: Icons.handshake_outlined,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(b2bPartnerCandidatesProvider(business));
                },
                color: _darkGreen,
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final partner = candidates[index];
                    return _B2bMatchCard(
                      business: business,
                      partner: partner,
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _B2bMatchCard extends ConsumerWidget {
  final Business business;
  final Business partner;

  const _B2bMatchCard({
    required this.business,
    required this.partner,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compatibilityAsync = ref.watch(
      b2bCompatibilityProvider(
        (myBusiness: business, targetBusiness: partner),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Partner info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  partner.category.name,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      partner.distance != null
                          ? '${partner.distance!.toStringAsFixed(1)} km away'
                          : 'Distance unknown',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    compatibilityAsync.when(
                      data: (result) => Text(
                        '${(result.compatibilityScore * 100).toInt()}% match',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _darkGreen,
                        ),
                      ),
                      loading: () => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => const Text(
                        '?',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Connect button – dark green
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connect feature coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}