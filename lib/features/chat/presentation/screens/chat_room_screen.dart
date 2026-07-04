import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:ifind/features/portfolio/presentation/screens/gallery_media_view_screen.dart';

// ── Wave painter (same as chat list) ────────────────────────────────────────
class _HeaderWavePainter extends CustomPainter {
  const _HeaderWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..cubicTo(size.width * 0.3, size.height * 0.25, size.width * 0.6,
          size.height * 0.8, size.width, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Date separator ───────────────────────────────────────────────────────────
class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500])),
      ),
    );
  }
}

// ── Business info card ───────────────────────────────────────────────────────
class _BusinessInfoCard extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final VoidCallback onViewShop;

  const _BusinessInfoCard({
    required this.name,
    required this.onViewShop,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(logoUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.storefront_outlined,
                            color: AppColors.primaryGreen)))
                : const Icon(Icons.storefront_outlined,
                    color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fashion & Footwear',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    ...List.generate(
                        4,
                        (_) => const Icon(Icons.star_rounded,
                            color: Color(0xFFFBBF24), size: 13)),
                    const Icon(Icons.star_half_rounded,
                        color: Color(0xFFFBBF24), size: 13),
                    const SizedBox(width: 4),
                    Text('4.8',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('2.5 km away  •  Responds in 2 mins',
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
          // View shop button
          GestureDetector(
            onTap: onViewShop,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.4),
                    width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View Shop',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      color: AppColors.primaryGreen, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Main screen ──────────────────────────────────────────────────────────────
class ChatRoomScreen extends ConsumerWidget {
  final Chat chat;
  final String otherPartyName;

  const ChatRoomScreen({
    super.key,
    required this.chat,
    required this.otherPartyName,
  });

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.rocket_launch_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$feature is coming soon!',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.deepGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _navigateToShop(BuildContext context, WidgetRef ref) async {
    final businessId = chat.businessId;
    if (businessId == null) {
      _comingSoon(context, 'View Shop');
      return;
    }
    final business =
        await ref.read(businessProvider(businessId).future);
    if (!context.mounted) return;
    if (business == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load shop details.',
              style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      return;
    }
    context.push('/business-details', extra: business);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    final isBusiness = chat.businessId != null || chat.isB2B;
    final logoUrl = chat.isB2B
        ? chat.partnerBusinessLogo
        : (chat.businessLogoUrl ?? chat.customerAvatarUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFF5FBF7),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Wave header ──────────────────────────────────────────────────
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(0)),
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF022C22),
                        Color(0xFF065F46),
                        Color(0xFF059669)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const Positioned.fill(
                        child:
                            CustomPaint(painter: _HeaderWavePainter()),
                      ),
                      Row(
                        children: [
                          // Back
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.35),
                                  width: 2),
                            ),
                            child: logoUrl != null
                                ? ClipOval(
                                    child: Image.network(logoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _avatarFallback(
                                                otherPartyName)))
                                : _avatarFallback(otherPartyName),
                          ),
                          const SizedBox(width: 10),
                          // Name + online
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        otherPartyName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (isBusiness) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded,
                                          color: Color(0xFF4ADE80),
                                          size: 15),
                                    ],
                                  ],
                                ),
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
                                    const SizedBox(width: 5),
                                    Text('Online',
                                        style: GoogleFonts.outfit(
                                            color: Colors.white
                                                .withValues(alpha: 0.70),
                                            fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Action icons
                          _HeaderAction(
                              icon: Icons.call_rounded,
                              onTap: () => _comingSoon(context, 'Voice calls')),
                          const SizedBox(width: 6),
                          _HeaderAction(
                              icon: Icons.videocam_rounded,
                              onTap: () => _comingSoon(context, 'Video calls')),
                          const SizedBox(width: 6),
                          _HeaderAction(
                              icon: Icons.more_vert_rounded,
                              onTap: () => _comingSoon(context, 'More options')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Business info card ─────────────────────────────────────────
              if (isBusiness)
                _BusinessInfoCard(
                  name: otherPartyName,
                  logoUrl: logoUrl,
                  onViewShop: () => _navigateToShop(context, ref),
                ),

              // ── Chat body ──────────────────────────────────────────────────
              Expanded(child: _ChatRoomBody(chat: chat)),
            ],
          ),

          // ── Floating AI assistant button ──────────────────────────────────
          Positioned(
            right: 16,
            bottom: 84,
            child: _AiAssistantButton(
              onTap: () => _showAiAssistantSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'B',
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // TODO: wire this up to the real AI assistant feature once the backend
  // endpoint exists (e.g. drafting replies, summarizing the thread, or
  // suggesting a quotation). For now it's a lightweight placeholder sheet.
  void _showAiAssistantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryGreen, Color(0xFF10B981)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('AI Assistant',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Draft replies, summarize this chat, or generate a quotation. Coming soon.',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: Colors.grey[500], height: 1.4),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiAssistantButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AiAssistantButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryGreen, Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.auto_awesome_rounded,
            color: Colors.white, size: 22),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ── Chat body (stateful) ─────────────────────────────────────────────────────
class _ChatRoomBody extends ConsumerStatefulWidget {
  final Chat chat;
  const _ChatRoomBody({required this.chat});

  @override
  ConsumerState<_ChatRoomBody> createState() => _ChatRoomBodyState();
}

class _ChatRoomBodyState extends ConsumerState<_ChatRoomBody> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Message> _optimisticMessages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom());
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _controller.clear();
    final tempMsg = Message(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chat.id,
      senderId: user.id,
      content: text,
      createdAt: DateTime.now(),
      isRead: false,
    );
    setState(() => _optimisticMessages.add(tempMsg));
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom());

    try {
      await ref.read(chatRemoteDataSourceProvider).sendMessage(
            chatId: widget.chat.id,
            senderId: user.id,
            content: text,
          );
      ref.invalidate(myChatsProvider);
      if (!widget.chat.isB2B && widget.chat.businessId != null) {
        ref.invalidate(businessChatsProvider(widget.chat.businessId!));
        ref.invalidate(
            unansweredContactsProvider(widget.chat.businessId!));
      }
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        AppToast.show(context, friendlyError(e), type: ToastType.error);
        setState(() => _optimisticMessages.remove(tempMsg));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(messagesStreamProvider(widget.chat.id));
    final currentUser = ref.watch(currentUserProvider);

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () =>
                const Center(child: IFindLoaderInline(size: 60)),
            error: (e, _) => ErrorRetryWidget(
              message: friendlyError(e),
              onRetry: () => ref.invalidate(
                  messagesStreamProvider(widget.chat.id)),
            ),
            data: (serverMessages) {
              _optimisticMessages.removeWhere((opt) =>
                  serverMessages.any((srv) =>
                      srv.senderId == opt.senderId &&
                      srv.content == opt.content &&
                      srv.createdAt
                              .difference(opt.createdAt)
                              .inSeconds
                              .abs() <
                          5));

              final all = [
                ...serverMessages,
                ..._optimisticMessages
              ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _scrollToBottom());

              if (all.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen
                              .withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded,
                            color: AppColors.primaryGreen, size: 28),
                      ),
                      const SizedBox(height: 14),
                      Text('Start the conversation',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('Say hello or share a product inquiry.',
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: Colors.grey[400])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: all.length,
                itemBuilder: (context, i) {
                  final msg = all[i];
                  final isMe = msg.senderId == currentUser?.id;

                  // Date separator
                  final showDate = i == 0 ||
                      !_sameDay(all[i - 1].createdAt, msg.createdAt);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showDate)
                        _DateSeparator(
                            label: _dateLabel(msg.createdAt)),
                      _MessageBubble(
                        msg: msg,
                        isMe: isMe,
                        senderInitial: isMe
                            ? null
                            : (widget.chat.businessName ??
                                        widget.chat.customerName ??
                                        'B')
                                    .isNotEmpty
                                ? (widget.chat.businessName ??
                                        widget.chat.customerName ??
                                        'B')[0]
                                    .toUpperCase()
                                : 'B',
                        senderLogoUrl: isMe
                            ? null
                            : (widget.chat.businessLogoUrl ??
                                widget.chat.customerAvatarUrl),
                        onDelete: isMe && !msg.id.startsWith('temp-')
                            ? () => _deleteMessage(msg)
                            : null,
                        onQuotationAccept: () => _handleQuotationAction(
                            msg, 'accepted'),
                        onQuotationDecline: () => _handleQuotationAction(
                            msg, 'declined'),
                        onQuotationCounter: () => _handleQuotationAction(
                            msg, 'counter offer requested'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        _InputArea(
          onSend: _sendMessage,
          controller: _controller,
          onComingSoon: (feature) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.rocket_launch_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('$feature is coming soon!',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ],
                ),
                backgroundColor: AppColors.deepGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // TODO: replace this with a real call once the backend exposes a
  // quotation-response endpoint (e.g. chatRemoteDataSource.respondToQuotation).
  void _handleQuotationAction(Message msg, String action) {
    if (mounted) {
      AppToast.show(context, 'Quotation $action', type: ToastType.success);
    }
  }

  Future<void> _deleteMessage(Message msg) async {
    try {
      await ref
          .read(chatRemoteDataSourceProvider)
          .deleteMessage(msg.id);
      ref.invalidate(messagesStreamProvider(widget.chat.id));
      ref.invalidate(myChatsProvider);
      if (mounted) {
        AppToast.show(context, 'Message deleted',
            type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, friendlyError(e), type: ToastType.error);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  static const _productInquiryPrefix = 'IFIND_PRODUCT_INQUIRY::';
  static const _quotationPrefix = 'IFIND_QUOTATION::';

  final Message msg;
  final bool isMe;
  final String? senderInitial;
  final String? senderLogoUrl;
  final VoidCallback? onDelete;
  final VoidCallback? onQuotationAccept;
  final VoidCallback? onQuotationDecline;
  final VoidCallback? onQuotationCounter;

  const _MessageBubble({
    required this.msg,
    required this.isMe,
    this.senderInitial,
    this.senderLogoUrl,
    this.onDelete,
    this.onQuotationAccept,
    this.onQuotationDecline,
    this.onQuotationCounter,
  });

  @override
  Widget build(BuildContext context) {
    final isOptimistic = msg.id.startsWith('temp-');
    final isProductInquiry =
        msg.content.startsWith(_productInquiryPrefix);
    final isRichInquiry = msg.content.startsWith('[MEDIA_INQUIRY]');
    final isQuotation = msg.content.startsWith(_quotationPrefix);

    String displayContent = msg.content;
    String? mediaUrl;
    String? mediaType;
    String? productTitle;
    String? productPrice;
    bool hasCard = false;

    Map<String, dynamic>? quotationData;
    if (isQuotation) {
      try {
        quotationData = jsonDecode(
                msg.content.substring(_quotationPrefix.length))
            as Map<String, dynamic>;
      } catch (_) {
        quotationData = null;
      }
    } else if (isProductInquiry) {
      try {
        final raw =
            msg.content.substring(_productInquiryPrefix.length);
        final data = jsonDecode(raw) as Map<String, dynamic>;
        mediaType = data['media_type'] as String?;
        mediaUrl =
            (data['thumbnail_url'] ?? data['media_url']) as String?;
        displayContent = data['message'] as String? ??
            'I am interested in this item.';
        productTitle = data['title'] as String? ?? 'Product inquiry';
        final price = data['price'];
        if (price is num) {
          productPrice =
              'UGX ${price.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}';
        }
        hasCard = mediaUrl != null;
      } catch (_) {}
    } else if (isRichInquiry) {
      try {
        final parts = msg.content.split('|');
        if (parts.length >= 3) {
          mediaType = parts[1];
          mediaUrl = parts[2];
          displayContent =
              parts.length > 3 ? parts[3] : 'Interested in this item';
          hasCard = true;
        }
      } catch (_) {}
    }

    return GestureDetector(
      onLongPress: onDelete != null
          ? () => _showMenu(context)
          : null,
      child: Opacity(
        opacity: isOptimistic ? 0.72 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Sender avatar (incoming only)
              if (!isMe) ...[
                _SenderAvatar(
                  initial: senderInitial ?? 'B',
                  logoUrl: senderLogoUrl,
                ),
                const SizedBox(width: 8),
              ],

              // Quotation card renders standalone, matching the reference
              // design (a white card, not tinted by the bubble gradient).
              if (isQuotation && quotationData != null)
                Flexible(
                  child: _QuotationCard(
                    data: quotationData,
                    createdAt: msg.createdAt,
                    onAccept: onQuotationAccept,
                    onDecline: onQuotationDecline,
                    onCounter: onQuotationCounter,
                  ),
                )
              else
                // Bubble
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF059669),
                                Color(0xFF065F46),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isMe ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(22),
                        topRight: const Radius.circular(22),
                        bottomLeft:
                            Radius.circular(isMe ? 22 : 4),
                        bottomRight:
                            Radius.circular(isMe ? 4 : 22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isMe
                              ? AppColors.primaryGreen
                                  .withValues(alpha: 0.20)
                              : Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(22),
                        topRight: const Radius.circular(22),
                        bottomLeft:
                            Radius.circular(isMe ? 22 : 4),
                        bottomRight:
                            Radius.circular(isMe ? 4 : 22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            // Product / media card
                            if (hasCard && mediaUrl != null) ...[
                              _ProductCard(
                                mediaUrl: mediaUrl,
                                mediaType: mediaType,
                                title: productTitle,
                                price: productPrice,
                                isMe: isMe,
                                onTap: () => _openMedia(
                                    context, mediaUrl!, mediaType,
                                    productTitle,
                                    msg.createdAt),
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Text
                            Text(
                              displayContent,
                              style: GoogleFonts.outfit(
                                color: isMe
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Time + status
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timeago.format(msg.createdAt,
                                      locale: 'en_short'),
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                            .withValues(alpha: 0.65)
                                        : Colors.grey[400],
                                    fontSize: 10,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    isOptimistic
                                        ? Icons.access_time_rounded
                                        : Icons.done_all_rounded,
                                    size: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.65),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (isMe) const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              title: Text('Delete message',
                  style: GoogleFonts.outfit()),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openMedia(BuildContext context, String url, String? type,
      String? caption, DateTime createdAt) {
    final item = PortfolioItem(
      id: 'inquiry-media',
      businessId: '',
      mediaType: type == 'video' ? MediaType.video : MediaType.image,
      mediaUrl: url,
      caption: caption,
      createdAt: createdAt,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => GalleryMediaViewScreen(item: item)),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  final String initial;
  final String? logoUrl;
  const _SenderAvatar({required this.initial, this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGreen.withValues(alpha: 0.12),
        border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            width: 1.5),
      ),
      child: logoUrl != null
          ? ClipOval(
              child: Image.network(logoUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                      child: Text(initial,
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen)))))
          : Center(
              child: Text(initial,
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen)),
            ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String mediaUrl;
  final String? mediaType;
  final String? title;
  final String? price;
  final bool isMe;
  final VoidCallback onTap;

  const _ProductCard({
    required this.mediaUrl,
    this.mediaType,
    this.title,
    this.price,
    required this.isMe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isMe
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: mediaUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey.shade300,
                        child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 20)),
                  ),
                  if (mediaType == 'video')
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 14),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product inquiry',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.primaryGreen,
                      ),
                    ),
                    if (title != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                    if (price != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        price!,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quotation card ───────────────────────────────────────────────────────────
// Expects messages formatted as:
//   IFIND_QUOTATION::{"items":"30 Pairs Nike Air Max","total":5400000,"status":"pending"}
// `status` can be 'pending' | 'accepted' | 'declined' — once accepted or
// declined server-side, the action row is replaced with a simple status pill.
class _QuotationCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCounter;

  const _QuotationCard({
    required this.data,
    required this.createdAt,
    this.onAccept,
    this.onDecline,
    this.onCounter,
  });

  String _formatUgx(num value) {
    return 'UGX ${value.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}';
  }

  @override
  Widget build(BuildContext context) {
    final items = data?['items']?.toString() ?? 'Items';
    final totalRaw = data?['total'];
    final total = totalRaw is num ? _formatUgx(totalRaw) : (totalRaw?.toString() ?? '—');
    final status = (data?['status'] as String?) ?? 'pending';

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_rounded,
                      color: AppColors.primaryGreen, size: 15),
                ),
                const SizedBox(width: 8),
                Text('Quotation',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.grey[500])),
                Flexible(
                  child: Text(items,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.outfit(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.grey[500])),
                Text(total,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(createdAt, locale: 'en_short'),
              style: GoogleFonts.outfit(
                  fontSize: 10, color: Colors.grey[400]),
            ),
            const SizedBox(height: 10),
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onAccept,
                      child: Text('Accept',
                          style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: BorderSide(
                            color: AppColors.primaryGreen.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onCounter,
                      child: Text('Counter',
                          style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onDecline,
                      child: Text('Decline',
                          style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: status == 'accepted'
                      ? AppColors.primaryGreen.withValues(alpha: 0.10)
                      : Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    status == 'accepted' ? 'Accepted' : 'Declined',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: status == 'accepted'
                          ? AppColors.primaryGreen
                          : Colors.redAccent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Input area ────────────────────────────────────────────────────────────────
class _InputArea extends StatelessWidget {
  final VoidCallback onSend;
  final TextEditingController controller;
  final void Function(String feature) onComingSoon;

  const _InputArea({
    required this.onSend,
    required this.controller,
    required this.onComingSoon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment icons — scrollable so new options (docs, quotes)
            // don't get cramped on smaller screens.
            SizedBox(
              height: 34,
              width: 168,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _AttachBtn(
                      icon: Icons.image_outlined,
                      onTap: () => onComingSoon('Photo sharing')),
                  const SizedBox(width: 4),
                  _AttachBtn(
                      icon: Icons.camera_alt_outlined,
                      onTap: () => onComingSoon('Camera')),
                  const SizedBox(width: 4),
                  _AttachBtn(
                      icon: Icons.location_on_outlined,
                      onTap: () => onComingSoon('Location sharing')),
                  const SizedBox(width: 4),
                  _AttachBtn(
                      icon: Icons.inventory_2_outlined,
                      onTap: () => onComingSoon('Product sharing')),
                  const SizedBox(width: 4),
                  _AttachBtn(
                      icon: Icons.description_outlined,
                      onTap: () => onComingSoon('File attachments')),
                  const SizedBox(width: 4),
                  _AttachBtn(
                      icon: Icons.attach_money_rounded,
                      onTap: () => onComingSoon('Quotation builder')),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // Text field
            Expanded(
              child: Container(
                constraints:
                    const BoxConstraints(maxHeight: 120, minHeight: 44),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.grey.shade200, width: 1),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.outfit(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: GoogleFonts.outfit(
                        color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.deepGreen,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen
                          .withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
}

class _AttachBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AttachBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 17),
      ),
    );
  }
}