import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to inquire')));
      return;
    }

    try {
      final chatDataSource = ref.read(chatRemoteDataSourceProvider);
      final chat = await chatDataSource.getOrCreateChat(
        customerId: user.id,
        businessId: widget.businessId,
      );

      final inquiryMessage =
          '[MEDIA_INQUIRY]|${widget.item.mediaType.name}|${widget.item.mediaUrl}|Interested in: ${widget.item.caption ?? 'this product'}';
      await chatDataSource.sendMessage(
        chatId: chat.id,
        senderId: user.id,
        content: inquiryMessage,
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
                    onTap: () {
                      if (ref.read(currentUserProvider) == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please login to like products')),
                        );
                        return;
                      }
                      ref.read(toggleLikeProvider(widget.item.id));
                    },
                  ),
                  const SizedBox(height: 24),
                  _InteractionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Comment',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Comments coming soon!')));
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
                    label: 'Message',
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
              const Center(child: CircularProgressIndicator()),
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
