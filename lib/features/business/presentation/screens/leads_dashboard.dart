import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/needs/domain/entities/need.dart';
import 'package:ifind/features/needs/presentation/providers/need_provider.dart';
import 'package:ifind/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:ifind/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class LeadsDashboardScreen extends ConsumerWidget {
  const LeadsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsAsync = ref.watch(nearbyNeedsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Leads', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final user = ref.watch(currentUserProvider);
              // Mock business ID or fetch from user's business
              // For MVP, assuming user.id is business owner and we fetch their first business
              final myBusinessesAsync = ref.watch(myBusinessesProvider(user?.id ?? ''));
              final businessId = myBusinessesAsync.value?.firstOrNull?.id;

              if (businessId == null) return const SizedBox.shrink();

              return NotificationBadge(
                businessId: businessId,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(businessId: businessId),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(nearbyNeedsProvider),
          ),
        ],
      ),
      body: needsAsync.when(
        data: (needs) {
          if (needs.isEmpty) {
            return const EmptyStateWidget(
              title: 'No new leads nearby',
              message: 'When customers post needs matching your category, they will appear here.',
              icon: Icons.assignment_late_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: needs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _LeadCard(need: needs[index])
                .animate()
                .fadeIn(delay: (index * 100).ms)
                .slideY(begin: 0.1);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _LeadCard extends ConsumerWidget {
  final Need need;
  const _LeadCard({required this.need});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerProfileAsync = ref.watch(userProfileProvider(need.userId));

    return Container(
      padding: const EdgeInsets.all(20),
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
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  need.category,
                  style: GoogleFonts.outfit(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                timeago.format(need.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            need.title,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          customerProfileAsync.when(
            data: (customer) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'from ${customer.fullName}',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (need.description != null && need.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              need.description!,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final customer = customerProfileAsync.value;
                if (customer != null && customer.phone != null) {
                  final cleanPhone = customer.phone!.replaceAll(RegExp(r'[^0-9]'), '');
                  final whatsappPhone = cleanPhone.startsWith('256') ? cleanPhone : '256$cleanPhone';
                  final uri = Uri.parse('https://wa.me/$whatsappPhone?text=Hi ${customer.fullName.split(" ").first}, I saw your request for "${need.title}" on iFind.');
                  
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open WhatsApp')),
                    );
                  }
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer phone not available')),
                  );
                }
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Connect with Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
