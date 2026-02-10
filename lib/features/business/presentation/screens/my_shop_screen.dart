import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/business/presentation/screens/create_business_screen.dart';
import 'package:ifind/features/business/presentation/screens/leads_dashboard.dart';
import 'package:ifind/features/business/presentation/screens/shop_gallery_screen.dart';
import 'package:ifind/features/business/presentation/screens/product_management_screen.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';

class MyShopScreen extends ConsumerWidget {
  const MyShopScreen({super.key});

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  Future<void> _deleteShop(BuildContext context, WidgetRef ref, String businessId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Shop', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text('This action is permanent. All your products, gallery media, and shop data will be deleted forever.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(businessRepositoryProvider);
      final user = ref.read(currentUserProvider);
      final result = await repository.deleteBusiness(businessId);
      
      result.fold(
        (failure) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${failure.message}')));
          }
        },
        (_) {
          if (user != null) {
            ref.invalidate(myBusinessesProvider(user.id));
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop deleted successfully')));
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final myBusinessesAsync = ref.watch(myBusinessesProvider(user.id));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('My Shop Space', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.grey),
            tooltip: 'Sign Out',
            onPressed: () => _handleSignOut(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to Settings
            },
          ),
        ],
      ),
      body: myBusinessesAsync.when(
        data: (businesses) {
          if (businesses.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(myBusinessesProvider(user.id)),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
                  child: EmptyStateWidget(
                    title: 'No shop yet',
                    message: 'Launch your digital shop and start growing your business today.',
                    icon: Icons.rocket_launch_rounded,
                    actionLabel: 'Create My Shop',
                    onAction: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const CreateBusinessScreen())
                    ),
                  ),
                ),
              ),
            );
          }

          final business = businesses.first; // For MVP, assuming one business per user

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myBusinessesProvider(user.id)),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildShopHeader(context, business),
                const SizedBox(height: 32),
                _buildManagementGrid(context, ref, business),
                const SizedBox(height: 32),
                _buildRecentStats(),
                const SizedBox(height: 100), // Space for floating nav
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildShopHeader(BuildContext context, Business business) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Icon(Icons.storefront_rounded, color: AppColors.primaryGreen, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name,
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  business.category.toString().split('.').last.toUpperCase(),
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryGreen),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => CreateBusinessScreen(business: business))
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementGrid(BuildContext context, WidgetRef ref, Business business) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildManageCard(
          context,
          'Leads Hub',
          '${business.reviewCount} Potential Customers',
          Icons.assignment_ind_rounded,
          Colors.blue,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeadsDashboardScreen())),
        ),
        _buildManageCard(
          context,
          'Products',
          'Manage your catalog',
          Icons.inventory_2_rounded,
          Colors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductManagementScreen())),
        ),
        _buildManageCard(
          context,
          'Shop Media',
          'Photos and Videos',
          Icons.collections_rounded,
          Colors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopGalleryScreen(business: business))),
        ),
        _buildManageCard(
          context,
          'Delete Shop',
          'Close shop permanently',
          Icons.delete_forever_rounded,
          Colors.red,
          () => _deleteShop(context, ref, business.id),
        ),
      ],
    );
  }

  Widget _buildManageCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Stats (Last 7 Days)', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Views', '1.2k', Colors.green),
              _buildStatItem('Claims', '48', Colors.blue),
              _buildStatItem('Rating', '4.8', Colors.amber),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
