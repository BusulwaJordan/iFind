import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/products/domain/entities/product.dart';
import 'package:ifind/features/products/presentation/providers/product_provider.dart';
import 'package:ifind/features/products/presentation/screens/add_product_screen.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState
    extends ConsumerState<ProductManagementScreen> {
  String? _selectedBusinessId;

  @override
  Widget build(BuildContext context) {
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

          final business = businesses.firstWhere(
            (b) => b.id == (_selectedBusinessId ?? businesses.first.id),
            orElse: () => businesses.first,
          );
          _selectedBusinessId ??= business.id;

          final productsAsync =
              ref.watch(businessProductsProvider(business.id));

          return productsAsync.when(
            data: (products) {
              final sortedProducts = [...products]..sort((a, b) {
                  if (a.isAvailable != b.isAvailable) {
                    return a.isAvailable ? -1 : 1;
                  }
                  return b.createdAt.compareTo(a.createdAt);
                });

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
                  itemCount: sortedProducts.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _BusinessSelector(
                        businesses: businesses,
                        selectedBusinessId: business.id,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedBusinessId = value);
                        },
                      );
                    }

                    final product = sortedProducts[index - 1];
                    return _ProductListTile(
                      product: product,
                      businessId: business.id,
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
      floatingActionButton: myBusinessesAsync.maybeWhen(
        data: (businesses) => businesses.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _navigateToAddProduct(
                    context, _selectedBusinessId ?? businesses.first.id),
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

class _BusinessSelector extends StatelessWidget {
  final List<Business> businesses;
  final String selectedBusinessId;
  final ValueChanged<String?> onChanged;

  const _BusinessSelector({
    required this.businesses,
    required this.selectedBusinessId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (businesses.length == 1) {
      return Text(
        businesses.first.name,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedBusinessId,
      decoration: const InputDecoration(
        labelText: 'Managing shop',
        prefixIcon: Icon(Icons.storefront_rounded),
      ),
      items: businesses
          .map((business) => DropdownMenuItem(
                value: business.id,
                child: Text(business.name),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ProductListTile extends ConsumerWidget {
  final Product product;
  final String businessId;
  const _ProductListTile({required this.product, required this.businessId});

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
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove "${product.name}" from your shop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final result =
        await ref.read(productRepositoryProvider).deleteProduct(product.id);
    if (!context.mounted) return;

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        ref.invalidate(businessProductsProvider(businessId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted')),
        );
      },
    );
  }
}
