import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/products/domain/entities/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final VoidCallback? onInquire;

  const ProductDetailScreen({super.key, required this.product, this.onInquire});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final formattedPrice =
        'UGX ${product.price.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 340,
            backgroundColor: AppColors.deepGreen,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: product.images.isEmpty
                  ? Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_rounded,
                            color: Colors.grey, size: 48),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: Colors.black),
                        PageView.builder(
                          controller: _pageController,
                          itemCount: product.images.length,
                          onPageChanged: (i) => setState(() => _currentPage = i),
                          itemBuilder: (context, index) => CachedNetworkImage(
                            imageUrl: product.images[index],
                            fit: BoxFit.contain,
                            placeholder: (_, __) => Container(color: Colors.grey.shade900),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade900,
                              child: const Icon(Icons.image_not_supported_rounded,
                                  color: Colors.grey, size: 48),
                            ),
                          ),
                        ),
                        if (product.images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(product.images.length, (i) {
                                final isActive = i == _currentPage;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: isActive ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: isActive ? 1 : 0.5),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ),
                        if (product.images.length > 1)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_currentPage + 1}/${product.images.length}',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: product.stockQuantity > 0 ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedPrice,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.stockQuantity > 0
                        ? '${product.stockQuantity} units in stock'
                        : 'Out of stock',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                  ),
                  if (product.description != null && product.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Description',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (widget.onInquire != null) ...[
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryGreen, AppColors.deepGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: widget.onInquire,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: Text('Inquire About This Product',
                            style: GoogleFonts.outfit(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  SizedBox(height: 20 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
