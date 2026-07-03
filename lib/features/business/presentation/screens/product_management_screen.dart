import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ifind/features/products/presentation/providers/product_provider.dart';
import 'package:ifind/features/products/domain/entities/product.dart';
import 'package:ifind/features/products/presentation/screens/add_product_screen.dart';
import 'package:ifind/features/products/presentation/screens/product_detail_screen.dart';
import 'package:intl/intl.dart';

class ProductManagementScreen extends ConsumerWidget {
  final String businessId;
  const ProductManagementScreen({super.key, required this.businessId});

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(productRepositoryProvider);
      final result = await repository.deleteProduct(product.id);
      result.fold(
        (failure) => AppToast.show(context, friendlyError(Exception(failure.message)), type: ToastType.error),
        (_) {
          ref.invalidate(businessProductsProvider(businessId));
          AppToast.show(context, 'Product deleted', type: ToastType.success);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(businessProductsProvider(businessId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          'Manage Catalog',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.deepGreen,
        elevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.deepGreen, AppColors.primaryGreen],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: productsAsync.when(
        data: (products) => Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(
              child: products.isEmpty
                  ? const EmptyStateWidget(
                      title: 'No products listed',
                      message: 'Add products to your shop to help customers find what you offer.',
                      icon: Icons.inventory_2_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return _ProductListTile(
                          product: products[index],
                          onDelete: () => _deleteProduct(context, ref, products[index]),
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddProductScreen(
                                businessId: businessId,
                                existingProduct: products[index],
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (index * 80).ms)
                            .slideX(begin: 0.05);
                      },
                    ),
            ),
          ],
        ),
        loading: () => const Center(child: IFindLoaderInline(size: 60)),
        error: (e, s) => ErrorRetryWidget(message: friendlyError(e), onRetry: () => ref.invalidate(businessProductsProvider(businessId))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddProductScreen(businessId: businessId)),
        ),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Product',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 4,
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryGreen, Color(0xFFF8FAFB)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 12),
                  Text('Search catalog...', style: GoogleFonts.outfit(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.primaryGreen, size: 20),
          ),
        ],
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  
  const _ProductListTile({
    required this.product,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: product.images.isNotEmpty
                ? Image.network(
                    product.images.first,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.darkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(product.price),
                  style: GoogleFonts.outfit(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (product.stockQuantity > 0 ? Colors.green : Colors.red)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.stockQuantity > 0
                        ? '${product.stockQuantity} units in stock'
                        : 'Out of stock',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: product.stockQuantity > 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 17, color: AppColors.primaryGreen),
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 17, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
            ),
          ),
        ),
      ),
    );
  }
}
