import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
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
    final businessAsync = ref.watch(businessProvider(chat.businessId));
    final displayName = businessAsync.when(
      data: (b) => b?.name ?? otherPartyName,
      loading: () => otherPartyName,
      error: (_, __) => otherPartyName,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayName,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Online',
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _ChatRoomBody(chat: chat),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe) {
    bool isOptimistic = msg.id.startsWith('temp-');
    bool isRichInquiry = msg.content.startsWith('[MEDIA_INQUIRY]');
    String displayContent = msg.content;
    String? mediaUrl;
    String? mediaType;
    String? caption;

    if (isRichInquiry) {
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
                  GestureDetector(
                    onTap: () {
                      final portfolioItem = PortfolioItem(
                        id: 'inquiry-media',
                        businessId: widget.chat.businessId,
                        mediaType: mediaType == 'video'
                            ? MediaType.video
                            : MediaType.image,
                        mediaUrl: mediaUrl!,
                        caption: caption,
                        createdAt: msg.createdAt,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GalleryMediaViewScreen(item: portfolioItem),
                        ),
                      );
                    },
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
                  ),
                  const SizedBox(height: 8),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.primaryGreen,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
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
