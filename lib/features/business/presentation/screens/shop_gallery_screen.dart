import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:ifind/features/portfolio/presentation/providers/portfolio_provider.dart';
import 'package:ifind/features/portfolio/presentation/screens/gallery_media_view_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShopGalleryScreen extends ConsumerStatefulWidget {
  final Business business;

  const ShopGalleryScreen({super.key, required this.business});

  @override
  ConsumerState<ShopGalleryScreen> createState() => _ShopGalleryScreenState();
}

class _ShopGalleryScreenState extends ConsumerState<ShopGalleryScreen> {
  final _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _deleteItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Media',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to remove this from your gallery?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(portfolioRepositoryProvider);
      final result = await repository.deletePortfolioItem(itemId);

      result.fold((failure) {
        if (mounted) {
          AppToast.show(context, 'Delete failed: ${failure.message}', type: ToastType.error);
        }
      }, (_) {
        ref.invalidate(portfolioProvider(widget.business.id));
        if (mounted) {
          AppToast.show(context, 'Removed successfully', type: ToastType.success);
        }
      });
    } catch (e) {
      if (mounted) {
        AppToast.show(context, friendlyError(e), type: ToastType.error);
      }
    }
  }

  Future<void> _addItem(MediaType type) async {
    final pickedFile = await (type == MediaType.image
        ? _picker.pickImage(source: ImageSource.gallery)
        : _picker.pickVideo(source: ImageSource.gallery));

    if (pickedFile == null) return;

    // Show caption and price input dialog
    if (!mounted) return;
    final result = await _showUploadDetailsDialog();
    if (result == null) return; // User cancelled

    final caption = result['caption'] as String?;
    final price = result['price'] as double?;

    setState(() => _isUploading = true);

    try {
      final repository = ref.read(portfolioRepositoryProvider);
      final uploadResult = await repository.uploadPortfolioItem(
        businessId: widget.business.id,
        file: pickedFile,
        type: type,
        caption: caption?.isEmpty == true ? null : caption,
        price: price,
      );

      uploadResult.fold((failure) {
        if (mounted) {
          AppToast.show(context, 'Upload failed: ${failure.message}', type: ToastType.error);
        }
      }, (item) {
        ref.invalidate(portfolioProvider(widget.business.id));
        if (mounted) {
          AppToast.show(context, 'Success! Item uploaded to gallery.', type: ToastType.success);
        }
      });
    } catch (e) {
      if (mounted) {
        AppToast.show(context, friendlyError(e), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<Map<String, dynamic>?> _showUploadDetailsDialog() async {
    final captionController = TextEditingController();
    final priceController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Post to Gallery',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: captionController,
              maxLength: 100,
              maxLines: 2,
              style: GoogleFonts.outfit(),
              decoration: InputDecoration(
                labelText: 'Caption (Optional)',
                hintText: 'Describe this product...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(),
              decoration: InputDecoration(
                labelText: 'Price (Optional)',
                hintText: 'UGX',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.payments_outlined, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child:
                Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final priceStr = priceController.text.trim();
              final price = double.tryParse(priceStr.replaceAll(',', ''));
              Navigator.pop(context, {
                'caption': captionController.text.trim(),
                'price': price,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Post Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final galleryItemsAsync = ref.watch(portfolioProvider(widget.business.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: Text('Manage Gallery',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: galleryItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20)
                      ],
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined,
                        size: 48, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Text('Your gallery is empty',
                      style: GoogleFonts.outfit(
                          fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Start adding products to attract customers',
                      style: GoogleFonts.outfit(color: Colors.grey)),
                  const SizedBox(height: 32),
                  _buildUploadButtons(),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(portfolioProvider(widget.business.id));
              return await ref
                  .read(portfolioProvider(widget.business.id).future);
            },
            child: Stack(
              children: [
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GalleryMediaViewScreen(item: item),
                                ),
                              ),
                              onLongPress: () => _deleteItem(item.id),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                    child: item.mediaType == MediaType.image
                                        ? CachedNetworkImage(
                                            imageUrl: item.mediaUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                                    color: Colors.grey[100]),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          )
                                        : (item.thumbnailUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl: item.thumbnailUrl!,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                        color:
                                                            Colors.grey[100]),
                                                errorWidget: (context, url,
                                                        error) =>
                                                    _buildVideoPlaceholder(),
                                                memCacheHeight: 240,
                                                memCacheWidth: 240,
                                              )
                                            : _buildVideoPlaceholder()),
                                  ),
                                  if (item.mediaType == MediaType.video)
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 28),
                                      ),
                                    ),

                                  // High-End Bold Price Tag
                                  if (item.price != null)
                                    Positioned(
                                      top: 12,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryGreen
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'UGX ${item.price!.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Quick Delete
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () => _deleteItem(item.id),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded,
                                            color: Colors.white, size: 11),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                            child: Text(
                              item.caption ?? 'Premium Product',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (_isUploading)
                  Container(
                    color: Colors.black45,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const IFindLoader(size: 60, showLabel: false),
                          const SizedBox(height: 16),
                          Text('Uploading to iFind...',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: IFindLoaderInline(size: 60)),
        error: (e, s) => ErrorRetryWidget(message: friendlyError(e), onRetry: () => ref.invalidate(portfolioProvider(widget.business.id))),
      ),
      floatingActionButton: _buildUploadFAB(),
    );
  }

  Widget _buildUploadFAB() {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text('Add to Gallery',
                    style: GoogleFonts.outfit(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      icon: Icons.image_rounded,
                      label: 'Photo',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _addItem(MediaType.image);
                      },
                    ),
                    _buildOptionButton(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _addItem(MediaType.video);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      backgroundColor: AppColors.primaryGreen,
      child: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
    );
  }

  Widget _buildOptionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUploadButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => _addItem(MediaType.image),
          icon: const Icon(Icons.image_rounded),
          label: const Text('Add Photo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _addItem(MediaType.video),
          icon: const Icon(Icons.videocam_rounded),
          label: const Text('Add Video'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.movie_creation_outlined,
            color: Colors.grey[400], size: 32),
      ),
    );
  }
}
