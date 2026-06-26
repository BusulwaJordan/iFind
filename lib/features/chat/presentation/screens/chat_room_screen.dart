import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:ifind/features/portfolio/presentation/screens/gallery_media_view_screen.dart';

class ChatRoomScreen extends ConsumerWidget {
  final Chat chat;
  final String otherPartyName;

  const ChatRoomScreen({
    super.key,
    required this.chat,
    required this.otherPartyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = chat.businessId != null
        ? ref.watch(businessProvider(chat.businessId!))
        : const AsyncValue<Business?>.data(null);
    final displayName = businessAsync.when(
      data: (b) => b?.name ?? otherPartyName,
      loading: () => otherPartyName,
      error: (_, __) => otherPartyName,
    );

    final business = businessAsync.valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          // ── Green gradient app bar ──────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 12, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF003D2B), Color(0xFF006241)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                // Business logo
                business?.logoUrl != null
                    ? CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(business!.logoUrl!),
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.15),
                      )
                    : CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'B',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('Active',
                              style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Chat body ──────────────────────────────────────────────────
          Expanded(child: _ChatRoomBody(chat: chat)),
        ],
      ),
    );
  }
}

class _ChatRoomBody extends ConsumerStatefulWidget {
  final Chat chat;
  const _ChatRoomBody({required this.chat});

  @override
  ConsumerState<_ChatRoomBody> createState() => _ChatRoomBodyState();
}

class _ChatRoomBodyState extends ConsumerState<_ChatRoomBody> {
  static const _productInquiryPrefix = 'IFIND_PRODUCT_INQUIRY::';
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Message> _optimisticMessages = [];

  @override
  void initState() {
    super.initState();
    // Auto-scroll to bottom when messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final content = _controller.text;
    _controller.clear();

    // Optimistic Update
    final tempMsg = Message(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chat.id,
      senderId: user.id,
      content: content,
      createdAt: DateTime.now(),
      isRead: false,
    );

    setState(() {
      _optimisticMessages.add(tempMsg);
    });

    // Auto-scroll to latest message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      await ref.read(chatRemoteDataSourceProvider).sendMessage(
            chatId: widget.chat.id,
            senderId: user.id,
            content: content,
          );

      // Refresh the chats list to update last message
      ref.invalidate(myChatsProvider);

      // Auto-scroll after message sent
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        AppToast.show(context, friendlyError(e), type: ToastType.error);
        setState(() {
          _optimisticMessages.remove(tempMsg);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.chat.id));
    final currentUser = ref.watch(currentUserProvider);

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            data: (serverMessages) {
              _optimisticMessages.removeWhere((opt) => serverMessages.any(
                  (srv) =>
                      srv.senderId == opt.senderId &&
                      srv.content == opt.content &&
                      srv.createdAt.difference(opt.createdAt).inSeconds.abs() <
                          5));

              final allMessages = [...serverMessages, ..._optimisticMessages];
              allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

              // Auto-scroll after messages update
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });

              if (allMessages.isEmpty) {
                return Center(
                    child: Text('Start a conversation...',
                        style: GoogleFonts.outfit(color: Colors.grey)));
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: allMessages.length,
                itemBuilder: (context, index) {
                  final msg = allMessages[index];
                  final isMe = msg.senderId == currentUser?.id;
                  return _buildMessageBubble(msg, isMe);
                },
              );
            },
            loading: () => const Center(child: IFindLoaderInline(size: 60)),
            error: (e, s) => ErrorRetryWidget(message: friendlyError(e), onRetry: () => ref.invalidate(messagesStreamProvider(widget.chat.id))),
          ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe) {
    bool isOptimistic = msg.id.startsWith('temp-');
    bool isRichInquiry = msg.content.startsWith('[MEDIA_INQUIRY]');
    bool isProductInquiry = msg.content.startsWith(_productInquiryPrefix);
    String displayContent = msg.content;
    String? mediaUrl;
    String? mediaType;
    String? caption;
    String? productTitle;
    String? productPrice;

    if (isProductInquiry) {
      try {
        final raw = msg.content.substring(_productInquiryPrefix.length);
        final data = jsonDecode(raw) as Map<String, dynamic>;
        mediaType = data['media_type'] as String?;
        mediaUrl = (data['thumbnail_url'] ?? data['media_url']) as String?;
        caption = data['message'] as String? ?? 'I am interested in this item.';
        productTitle = data['title'] as String? ?? 'Product inquiry';
        final price = data['price'];
        if (price is num) {
          productPrice = _formatPrice(price.toDouble());
        }
        displayContent = caption;
      } catch (_) {
        isProductInquiry = false;
      }
    } else if (isRichInquiry) {
      try {
        final parts = msg.content.split('|');
        if (parts.length >= 3) {
          mediaType = parts[1];
          mediaUrl = parts[2];
          caption = parts.length > 3 ? parts[3] : 'Interested in this item';
          displayContent = caption;
        }
      } catch (_) {}
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: !isOptimistic && isMe ? () => _showMessageMenu(msg) : null,
        child: Opacity(
          opacity: isOptimistic ? 0.7 : 1.0,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primaryGreen : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
              boxShadow: [
                if (!isMe)
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (isRichInquiry && mediaUrl != null) ...[
                  _buildInquiryMediaPreview(
                    mediaUrl: mediaUrl,
                    mediaType: mediaType,
                    caption: caption,
                    createdAt: msg.createdAt,
                  ),
                  const SizedBox(height: 8),
                ],
                if (isProductInquiry && mediaUrl != null) ...[
                  _buildProductInquiryCard(
                    mediaUrl: mediaUrl,
                    mediaType: mediaType,
                    title: productTitle ?? 'Product inquiry',
                    price: productPrice,
                    createdAt: msg.createdAt,
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  displayContent,
                  style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeago.format(msg.createdAt, locale: 'en_short'),
                      style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey,
                          fontSize: 10),
                    ),
                    if (isOptimistic) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.access_time,
                          size: 10, color: Colors.white70),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInquiryCard({
    required String mediaUrl,
    required String? mediaType,
    required String title,
    required String? price,
    required DateTime createdAt,
  }) {
    return GestureDetector(
      onTap: () => _openInquiryMedia(mediaUrl, mediaType, title, createdAt),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: mediaUrl,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 58,
                  height: 58,
                  color: Colors.grey.shade200,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 58,
                  height: 58,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product inquiry',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (price != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      price,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiryMediaPreview({
    required String mediaUrl,
    required String? mediaType,
    required String? caption,
    required DateTime createdAt,
  }) {
    return GestureDetector(
      onTap: () => _openInquiryMedia(mediaUrl, mediaType, caption, createdAt),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: mediaUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: Colors.grey[200], height: 120),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                height: 120,
                child: const Icon(Icons.error),
              ),
            ),
            if (mediaType == 'video')
              const Icon(Icons.play_circle_fill,
                  color: Colors.white70, size: 40),
          ],
        ),
      ),
    );
  }

  void _openInquiryMedia(
    String mediaUrl,
    String? mediaType,
    String? caption,
    DateTime createdAt,
  ) {
    final portfolioItem = PortfolioItem(
      id: 'inquiry-media',
      businessId: widget.chat.businessId ?? '',
      mediaType: mediaType == 'video' ? MediaType.video : MediaType.image,
      mediaUrl: mediaUrl,
      caption: caption,
      createdAt: createdAt,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GalleryMediaViewScreen(item: portfolioItem),
      ),
    );
  }

  String _formatPrice(double price) {
    return 'UGX ${price.toInt().toString().replaceAllMapped(
          RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
          (match) => "${match[1]},",
        )}';
  }

  void _showMessageMenu(Message msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 36,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Delete Message'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(msg);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(Message msg) async {
    try {
      await ref.read(chatRemoteDataSourceProvider).deleteMessage(msg.id);
      ref.invalidate(messagesStreamProvider(widget.chat.id));
      ref.invalidate(myChatsProvider);
      if (mounted) {
        AppToast.show(context, 'Message deleted', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, friendlyError(e), type: ToastType.error);
      }
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.outfit(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryGreen, AppColors.deepGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
