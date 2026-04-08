import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/products/domain/entities/product.dart';
import 'package:ifind/features/products/presentation/providers/product_provider.dart';
import 'package:ifind/features/products/presentation/screens/add_product_screen.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductManagementScreen extends ConsumerWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    final myBusinessesAsync = ref.watch(myBusinessesProvider(user.id));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('My Products',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: myBusinessesAsync.when(
        data: (businesses) {
          if (businesses.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Shop Found',
              message: 'You need to create a shop before adding products.',
              icon: Icons.storefront_rounded,
            );
          }

          final business = businesses.first;
          final productsAsync =
              ref.watch(businessProductsProvider(business.id));

          return productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return EmptyStateWidget(
                  title: 'No products yet',
                  message:
                      'Start adding products to your shop to attract customers.',
                  icon: Icons.inventory_2_rounded,
                  actionLabel: 'Add First Product',
                  onAction: () => _navigateToAddProduct(context, business.id),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.refresh(businessProductsProvider(business.id)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductListTile(product: product);
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
      floatingActionButton: myBusinessesAsync.maybeWhen(
        data: (businesses) => businesses.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () =>
                    _navigateToAddProduct(context, businesses.first.id),
                backgroundColor: AppColors.primaryGreen,
                label: const Text('Add Product',
                    style: TextStyle(color: Colors.white)),
                icon: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  void _navigateToAddProduct(BuildContext context, String businessId) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AddProductScreen(businessId: businessId)));
  }
}

class _ProductListTile extends ConsumerWidget {
  final Product product;
  const _ProductListTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: product.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: product.images.first,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.image_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.price.toStringAsFixed(0)} UGX',
                  style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock: ${product.stockQuantity}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.grey),
            onPressed: () {
              // Edit logic
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              // Delete logic
            },
          ),
        ],
      ),
    );
  }
}
