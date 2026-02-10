import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:ifind/features/portfolio/presentation/providers/portfolio_provider.dart';
import 'package:image_picker/image_picker.dart';

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
        title: Text('Delete Media', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this from your gallery?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
      await repository.deletePortfolioItem(itemId);
      
      ref.invalidate(portfolioProvider(widget.business.id));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  Future<void> _addItem(MediaType type) async {
    final pickedFile = await (type == MediaType.image 
        ? _picker.pickImage(source: ImageSource.gallery) 
        : _picker.pickVideo(source: ImageSource.gallery));

    if (pickedFile == null) return;

    // Show caption input dialog
    if (!mounted) return;
    final caption = await _showCaptionDialog();
    if (caption == null) return; // User cancelled

    setState(() => _isUploading = true);

    try {
      final repository = ref.read(portfolioRepositoryProvider);
      await repository.uploadPortfolioItem(
        businessId: widget.business.id,
        file: File(pickedFile.path),
        type: type,
        caption: caption.isEmpty ? null : caption,
      );
      
      ref.invalidate(portfolioProvider(widget.business.id));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<String?> _showCaptionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Caption', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add a caption, price, or description (optional, max 100 characters)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLength: 100,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., "Fresh baked cake - 50,000 UGX"',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final galleryItemsAsync = ref.watch(portfolioProvider(widget.business.id));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Shop Gallery', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: galleryItemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No media yet', style: GoogleFonts.outfit(color: Colors.grey)),
                  const SizedBox(height: 24),
                  _buildUploadButtons(),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(portfolioProvider(widget.business.id));
            },
            child: Stack(
              children: [
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            item.mediaType == MediaType.video 
                                ? (item.thumbnailUrl ?? item.mediaUrl)
                                : item.mediaUrl,
                            fit: BoxFit.cover,
                          ),
                          if (item.mediaType == MediaType.video)
                            const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 48)),
                          
                          // Caption overlay at bottom
                          if (item.caption != null && item.caption!.isNotEmpty)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Text(
                                  item.caption!,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          
                          // Delete button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.black45,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: () => _deleteItem(item.id),
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                ),
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
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(portfolioProvider(widget.business.id)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildUploadFAB(),
    );
  }

  Widget _buildUploadFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add Media', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.image_rounded, color: Colors.blue),
                  title: const Text('Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _addItem(MediaType.image);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam_rounded, color: Colors.purple),
                  title: const Text('Video'),
                  onTap: () {
                    Navigator.pop(context);
                    _addItem(MediaType.video);
                  },
                ),
              ],
            ),
          ),
        );
      },
      backgroundColor: AppColors.primaryGreen,
      icon: const Icon(Icons.add_a_photo_rounded),
      label: const Text('Add Media'),
    );
  }

  Widget _buildUploadButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => _addItem(MediaType.image),
          icon: const Icon(Icons.image_rounded),
          label: const Text('Photo'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _addItem(MediaType.video),
          icon: const Icon(Icons.videocam_rounded),
          label: const Text('Video'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
        ),
      ],
    );
  }
}
