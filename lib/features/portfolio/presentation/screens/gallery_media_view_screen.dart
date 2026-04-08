import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:ifind/features/portfolio/presentation/providers/comment_provider.dart';
import 'package:ifind/features/portfolio/presentation/widgets/comments_bottom_sheet.dart';

class GalleryMediaViewScreen extends ConsumerStatefulWidget {
  final PortfolioItem item;
  final VoidCallback? onInquire;

  const GalleryMediaViewScreen({
    super.key,
    required this.item,
    this.onInquire,
  });

  @override
  ConsumerState<GalleryMediaViewScreen> createState() =>
      _GalleryMediaViewScreenState();
}

class _GalleryMediaViewScreenState
    extends ConsumerState<GalleryMediaViewScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isTogglingLike = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.mediaType == MediaType.video) {
      _initVideoPlayer();
    }
  }

  Future<void> _initVideoPlayer() async {
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.item.mediaUrl));
    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      placeholder: Container(color: Colors.black),
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primaryGreen,
        handleColor: AppColors.primaryGreen,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.white,
      ),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _handleShare() {
    final caption = widget.item.caption ?? '';
    final shareText = caption.isNotEmpty
        ? 'Check out this on iFind: ${widget.item.mediaUrl}\n\n$caption'
        : 'Check out this on iFind: ${widget.item.mediaUrl}';
    Share.share(shareText);
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: widget.item.mediaUrl));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard!')));
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) return;
    setState(() => _isTogglingLike = true);

    try {
      final repository = ref.read(commentRepositoryProvider);
      final result = await repository.toggleLike(widget.item.id);

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${failure.toString()}')),
            );
          }
        },
        (isLiked) {
          // Refresh like status and count
          ref.invalidate(userLikeStatusProvider(widget.item.id));
          ref.invalidate(likeCountProvider(widget.item.id));
        },
      );
    } finally {
      if (mounted) setState(() => _isTogglingLike = false);
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CommentsBottomSheet(portfolioItemId: widget.item.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final likeCountAsync = ref.watch(likeCountProvider(widget.item.id));
    final isLikedAsync = ref.watch(userLikeStatusProvider(widget.item.id));
    final commentCountAsync = ref.watch(commentCountProvider(widget.item.id));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _handleShare,
          ),
          IconButton(
            icon: const Icon(Icons.link_rounded),
            onPressed: _copyLink,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: widget.item.mediaType == MediaType.video
                ? (_chewieController != null &&
                        _chewieController!
                            .videoPlayerController.value.isInitialized
                    ? GestureDetector(
                        onTap: () {
                          if (_videoPlayerController!.value.isPlaying) {
                            _videoPlayerController!.pause();
                          } else {
                            _videoPlayerController!.play();
                          }
                          setState(() {});
                        },
                        child: Chewie(controller: _chewieController!),
                      )
                    : const CircularProgressIndicator(color: Colors.white))
                : CachedNetworkImage(
                    imageUrl: widget.item.mediaUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(color: Colors.white),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.black38,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_rounded,
                            color: Colors.white, size: 64),
                      ),
                    ),
                    memCacheHeight: 800,
                    memCacheWidth: 800,
                  ),
          ),

          // Bottom info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.item.price != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'UGX ${widget.item.price!.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  if (widget.item.caption != null &&
                      widget.item.caption!.isNotEmpty)
                    Text(
                      widget.item.caption!,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Like Button with Real Count
                      isLikedAsync.when(
                        data: (isLiked) => _SocialButton(
                          icon: isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          label: likeCountAsync.when(
                            data: (count) => count.toString(),
                            loading: () => '0',
                            error: (_, __) => '0',
                          ),
                          color: isLiked ? Colors.redAccent : Colors.white,
                          onTap: _toggleLike,
                        ),
                        loading: () => const _SocialButton(
                          icon: Icons.favorite_outline_rounded,
                          label: '...',
                          color: Colors.white,
                          onTap: null,
                        ),
                        error: (_, __) => const _SocialButton(
                          icon: Icons.favorite_outline_rounded,
                          label: '0',
                          color: Colors.white,
                          onTap: null,
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Comment Button with Real Count
                      commentCountAsync.when(
                        data: (count) => _SocialButton(
                          icon: Icons.mode_comment_outlined,
                          label: count.toString(),
                          color: Colors.white,
                          onTap: _showComments,
                        ),
                        loading: () => const _SocialButton(
                          icon: Icons.mode_comment_outlined,
                          label: '...',
                          color: Colors.white,
                          onTap: null,
                        ),
                        error: (_, __) => const _SocialButton(
                          icon: Icons.mode_comment_outlined,
                          label: '0',
                          color: Colors.white,
                          onTap: null,
                        ),
                      ),
                      const Spacer(),
                      if (widget.onInquire != null)
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: widget.onInquire,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor:
                                  AppColors.primaryGreen.withValues(alpha: 0.5),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              'I WANT THIS',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
