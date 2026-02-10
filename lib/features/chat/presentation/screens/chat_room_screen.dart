import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatRoomScreen extends ConsumerStatefulWidget {
  final Chat chat;
  final String otherPartyName;

  const ChatRoomScreen({
    super.key,
    required this.chat,
    required this.otherPartyName,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    ref.read(chatRemoteDataSourceProvider).sendMessage(
      chatId: widget.chat.id,
      senderId: user.id,
      content: _controller.text,
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.chat.id));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherPartyName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Online', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(child: Text('Start a conversation...', style: GoogleFonts.outfit(color: Colors.grey)));
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
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
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
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
            if (!isMe) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(msg.createdAt, locale: 'en_short'),
              style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
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
}
