import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ifind/core/providers/ai_providers.dart';
import 'package:ifind/core/services/interaction_service.dart';
import 'package:ifind/features/notifications/presentation/providers/notification_provider.dart';

import 'package:ifind/features/portfolio/presentation/providers/comment_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProductFeedScreen extends ConsumerStatefulWidget {
  final List<PortfolioItem> initialItems;
  final int startIndex;
  final String businessName;
  final String businessId;

  const ProductFeedScreen({
    super.key,
    required this.initialItems,
    this.startIndex = 0,
    required this.businessName,
    required this.businessId,
  });

  @override
  ConsumerState<ProductFeedScreen> createState() => _ProductFeedScreenState();
}

class _ProductFeedScreenState extends ConsumerState<ProductFeedScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.startIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            itemCount: widget.initialItems.length,
            itemBuilder: (context, index) {
              final item = widget.initialItems[index];
              return _ProductItemView(
                item: item,
                businessName: widget.businessName,
                businessId: widget.businessId,
              );
            },
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Business Name at top
          Positioned(
            top: MediaQuery.of(context).padding.top + 15,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                widget.businessName,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [
                    const Shadow(color: Colors.black45, blurRadius: 10)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductItemView extends ConsumerStatefulWidget {
  final PortfolioItem item;
  final String businessName;
  final String businessId;

  const _ProductItemView({
    required this.item,
    required this.businessName,
    required this.businessId,
  });

  @override
  ConsumerState<_ProductItemView> createState() => _ProductItemViewState();
}

class _ProductItemViewState extends ConsumerState<_ProductItemView> {
  static const _productInquiryPrefix = 'IFIND_PRODUCT_INQUIRY::';
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.item.mediaType == MediaType.video) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.item.mediaUrl))
            ..initialize().then((_) {
              setState(() {});
              _videoController?.setLooping(true);
              _videoController?.play();
            });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _handleInquiry() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      AppToast.show(context, 'Please login to inquire', type: ToastType.info);
      return;
    }

    final message = await _showInquiryComposer();
    if (message == null || message.trim().isEmpty) return;

    try {
      final chatDataSource = ref.read(chatRemoteDataSourceProvider);
      final chat = await chatDataSource.getOrCreateChat(
        customerId: user.id,
        businessId: widget.businessId,
      );

      await chatDataSource.sendMessage(
        chatId: chat.id,
        senderId: user.id,
        content: _buildProductInquiryPayload(message.trim()),
      );

      // Log B2C interaction
      ref.read(interactionServiceProvider).logInteraction(
            userId: user.id,
            businessId: widget.businessId,
            type: InteractionType.inquirySent,
          );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              chat: chat,
              otherPartyName: widget.businessName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, friendlyError(e), type: ToastType.error);
      }
    }
  }

  Future<String?> _showInquiryComposer() async {
    final itemTitle = widget.item.caption?.trim().isNotEmpty == true
        ? widget.item.caption!.trim()
        : 'this product';
    final defaultMessage =
        'Hi ${widget.businessName}, I am interested in $itemTitle. Is it still available?';
    final controller = TextEditingController(text: defaultMessage);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Message seller',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl:
                            widget.item.thumbnailUrl ?? widget.item.mediaUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          if (widget.item.price != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatPrice(widget.item.price!),
                              style: GoogleFonts.outfit(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Write your message',
                    filled: true,
                    fillColor: const Color(0xFFF5F7F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, controller.text),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();
    return result;
  }

  String _buildProductInquiryPayload(String message) {
    return _productInquiryPrefix +
        jsonEncode({
          'version': 1,
          'portfolio_item_id': widget.item.id,
          'business_id': widget.businessId,
          'business_name': widget.businessName,
          'media_type': widget.item.mediaType.name,
          'media_url': widget.item.mediaUrl,
          'thumbnail_url': widget.item.thumbnailUrl,
          'title': widget.item.caption ?? 'Product inquiry',
          'price': widget.item.price,
          'message': message,
        });
  }

  Future<void> _handleLike() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      AppToast.show(context, 'Please login to like products', type: ToastType.info);
      return;
    }

    try {
      final isLiked = await ref.read(toggleLikeProvider(widget.item.id).future);
      if (!isLiked) return;

      final title = widget.item.caption?.trim().isNotEmpty == true
          ? widget.item.caption!.trim()
          : 'your product';
      await ref.read(notificationRepositoryProvider).createNotification(
        businessId: widget.businessId,
        type: 'product_like',
        title: 'New product like',
        body: '${user.fullName} liked $title.',
        data: {
          'portfolio_item_id': widget.item.id,
          'business_id': widget.businessId,
          'customer_id': user.id,
          'media_url': widget.item.mediaUrl,
          'thumbnail_url': widget.item.thumbnailUrl,
          'title': title,
        },
      );
    } catch (e) {
      if (mounted) {
        AppToast.show(context, friendlyError(e), type: ToastType.error);
      }
    }
  }

  String _formatPrice(double price) {
    return 'UGX ${price.toInt().toString().replaceAllMapped(
          RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
          (match) => "${match[1]},",
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Media Layer
        _buildMedia(),

        // Gradient Overlay for visibility
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // Caption and Product Info
        Positioned(
          bottom: 40,
          left: 20,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.item.price != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'UGX ${widget.item.price!.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              Text(
                widget.item.caption ?? 'Available at ${widget.businessName}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(widget.item.createdAt),
                    style:
                        GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Side Interaction Bar
        Positioned(
          right: 15,
          bottom: 100,
          child: Consumer(
            builder: (context, ref, child) {
              final isLikedAsync =
                  ref.watch(userLikeStatusProvider(widget.item.id));
              final isLiked = isLikedAsync.value ?? false;

              return Column(
                children: [
                  _InteractionButton(
                    icon: isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isLiked ? Colors.red : Colors.white,
                    label: 'Like',
                    onTap: _handleLike,
                  ),
                  const SizedBox(height: 24),
                  _InteractionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Comment',
                    onTap: () {
                      AppToast.show(context, 'Comments coming soon!', type: ToastType.info);
                    },
                  ),
                  const SizedBox(height: 24),
                  _InteractionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () {
                      Share.share(
                          'Check out this product from ${widget.businessName} on iFind!\n${widget.item.mediaUrl}');
                    },
                  ),
                  const SizedBox(height: 24),
                  _InteractionButton(
                    icon: Icons.message_rounded,
                    color: AppColors.primaryGreen,
                    label: 'I want this',
                    onTap: _handleInquiry,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMedia() {
    if (widget.item.mediaType == MediaType.image) {
      return CachedNetworkImage(
        imageUrl: widget.item.mediaUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            const Icon(Icons.error, color: Colors.white),
      );
    } else {
      return GestureDetector(
        onTap: () {
          if (_videoController == null) return;
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
          setState(() {});
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_videoController != null &&
                _videoController!.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else
              const Center(child: IFindLoaderInline(size: 60)),
            if (_videoController != null && !_videoController!.value.isPlaying)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 64),
                ),
              ),
          ],
        ),
      );
    }
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _InteractionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: color, size: 32),
          style: IconButton.styleFrom(
            backgroundColor: Colors.black26,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ).animate().scale(delay: 300.ms, duration: 300.ms);
  }
}
