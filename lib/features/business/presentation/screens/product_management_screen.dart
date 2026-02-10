import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';

class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Manage Products', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const EmptyStateWidget(
        title: 'No products listed',
        message: 'Add products to your shop to help customers find what you offer.',
        icon: Icons.inventory_2_outlined,
        actionLabel: 'Add Product',
        onAction: null, // To be implemented
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
    );
  }
}
