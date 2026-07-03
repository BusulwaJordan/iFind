import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/features/products/domain/entities/product.dart';
import 'package:ifind/features/products/presentation/providers/product_provider.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String businessId;
  final Product? existingProduct;
  const AddProductScreen({super.key, required this.businessId, this.existingProduct});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existingProduct?.name);
  late final _descriptionController =
      TextEditingController(text: widget.existingProduct?.description);
  late final _priceController =
      TextEditingController(text: widget.existingProduct?.price.toStringAsFixed(0));
  late final _stockController =
      TextEditingController(text: (widget.existingProduct?.stockQuantity ?? 10).toString());

  // Photos already uploaded (from an existing product being edited).
  late final List<String> _existingImageUrls = List.of(widget.existingProduct?.images ?? []);
  // Newly picked photos pending upload.
  final List<XFile> _newImages = [];
  final List<Uint8List> _newImageBytes = [];
  final _picker = ImagePicker();
  bool _isLoading = false;

  bool get _isEditing => widget.existingProduct != null;
  int get _totalPhotoCount => _existingImageUrls.length + _newImages.length;

  Future<void> _pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;
      setState(() {
        _newImages.add(pickedFile);
        _newImageBytes.add(bytes);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final stockQuantity = int.parse(_stockController.text.trim());

    final result = _isEditing
        ? await ref.read(productRepositoryProvider).updateProduct(
              productId: widget.existingProduct!.id,
              businessId: widget.businessId,
              name: name,
              description: description,
              price: price,
              stockQuantity: stockQuantity,
              existingImages: _existingImageUrls,
              newImageFiles: _newImages,
            )
        : await ref.read(productRepositoryProvider).createProduct(
              businessId: widget.businessId,
              name: name,
              description: description,
              price: price,
              stockQuantity: stockQuantity,
              imageFiles: _newImages,
            );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        AppToast.show(context, friendlyError(Exception(failure.message)),
            type: ToastType.error);
      },
      (product) {
        ref.invalidate(businessProductsProvider(widget.businessId));
        if (_isEditing) ref.invalidate(productByIdProvider(widget.existingProduct!.id));
        Navigator.pop(context);
        AppToast.show(
          context,
          _isEditing ? 'Product updated!' : 'Product added successfully!',
          type: ToastType.success,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.deepGreen,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              title: Text(
                _isEditing ? 'Edit Product' : 'Add New Product',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              flexibleSpace: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.deepGreen, AppColors.primaryGreen],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionCard(
                      title: 'Photos',
                      children: [_buildImageSection()],
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      title: 'Product Details',
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.outfit(),
                          decoration: _fieldDecoration(
                            label: 'Product Name',
                            icon: Icons.shopping_bag_outlined,
                            hint: 'e.g. Fresh Baked Bread',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          style: GoogleFonts.outfit(),
                          decoration: _fieldDecoration(
                            label: 'Description',
                            icon: Icons.description_outlined,
                            hint: 'What makes this product great?',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      title: 'Pricing & Stock',
                      children: [
                        TextFormField(
                          controller: _priceController,
                          style: GoogleFonts.outfit(),
                          decoration: _fieldDecoration(
                            label: 'Price (UGX)',
                            icon: Icons.payments_outlined,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (double.tryParse(value) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _stockController,
                          style: GoogleFonts.outfit(),
                          decoration: _fieldDecoration(
                            label: 'Stock Quantity',
                            icon: Icons.inventory_rounded,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (int.tryParse(value) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryGreen, AppColors.deepGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(_isEditing ? 'Save Changes' : 'Create Product',
                                style: GoogleFonts.outfit(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(height: 20 + MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final total = _totalPhotoCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          total == 0
              ? 'Add up to 5 photos — the first one is your cover photo'
              : '$total/5 photos added',
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: total + (total < 5 ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == total) {
                return InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 110,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined,
                            color: AppColors.primaryGreen, size: 24),
                        const SizedBox(height: 6),
                        Text(
                          'Add photo',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: AppColors.primaryGreen),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final isExisting = index < _existingImageUrls.length;

              return Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: isExisting
                        ? CachedNetworkImage(
                            imageUrl: _existingImageUrls[index],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.grey.shade200),
                          )
                        : Image.memory(
                            _newImageBytes[index - _existingImageUrls.length],
                            fit: BoxFit.cover,
                          ),
                  ),
                  if (index == 0)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Cover',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (isExisting) {
                          _existingImageUrls.removeAt(index);
                        } else {
                          final newIndex = index - _existingImageUrls.length;
                          _newImages.removeAt(newIndex);
                          _newImageBytes.removeAt(newIndex);
                        }
                      }),
                      child: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        radius: 12,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
