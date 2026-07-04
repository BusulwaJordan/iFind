import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
import 'package:ifind/core/widgets/empty_state_widget.dart';
import 'package:ifind/features/chat/presentation/providers/chat_provider.dart';
import 'package:ifind/features/chat/domain/entities/chat.dart';
import 'package:ifind/core/widgets/app_drawer.dart';
import 'package:timeago/timeago.dart' as timeago;

enum _ChatFilter { all, customers, businesses, unread, archived }

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  _ChatFilter _filter = _ChatFilter.all;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Chat> _applyFilter(List<Chat> chats) {
    var list = chats;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        final name = (c.businessName ?? c.customerName ?? c.partnerBusinessName ?? '').toLowerCase();
        final msg = (c.lastMessage ?? '').toLowerCase();
        return name.contains(q) || msg.contains(q);
      }).toList();
    }
    switch (_filter) {
      case _ChatFilter.customers:
        return list.where((c) => !c.isB2B && c.businessId != null).toList();
      case _ChatFilter.businesses:
        return list.where((c) => c.isB2B || c.businessId == null).toList();
      case _ChatFilter.unread:
        return list; // placeholder — no unread count in model yet
      case _ChatFilter.archived:
        return [];
      case _ChatFilter.all:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(myChatsProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5FBF7),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            // ── Wave header ────────────────────────────────────────────────
            _WaveHeader(
              topPad: topPad,
              chatsAsync: chatsAsync,
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (v) => setState(() => _searchQuery = v),
              onRefresh: () => ref.refresh(myChatsProvider),
            ),

            // ── Category chips ─────────────────────────────────────────────
            _CategoryChips(
              selected: _filter,
              onSelected: (f) => setState(() => _filter = f),
            ),

            // ── List ───────────────────────────────────────────────────────
            Expanded(
              child: chatsAsync.when(
                loading: () =>
                    const Center(child: IFindLoaderInline(size: 60)),
                error: (e, _) => ErrorRetryWidget(
                  message: friendlyError(e),
                  onRetry: () => ref.invalidate(myChatsProvider),
                ),
                data: (chats) {
                  final filtered = _applyFilter(chats);
                  if (filtered.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No conversations',
                      message:
                          'Start a conversation with a business or wait for customer inquiries.',
                      icon: Icons.forum_rounded,
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () async => ref.refresh(myChatsProvider),
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                          16, 8, 16, MediaQuery.of(context).padding.bottom + 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _ChatCard(
                        chat: filtered[i],
                        index: i,
                        // TODO: back these with real fields on Chat once
                        // available (pinned flag, unread counter, typing
                        // presence) — wiring is in place below, just pass
                        // the live values here instead of these defaults.
                        isPinned: false,
                        unreadCount: 0,
                        isTyping: false,
                        onDelete: () async {
                          final chat = filtered[i];
                          final name = chat.businessName ??
                              chat.customerName ??
                              chat.partnerBusinessName ??
                              'Chat';
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: Text('Delete chat?',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold)),
                              content: Text(
                                  'Remove your conversation with $name?',
                                  style: GoogleFonts.outfit()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            await ref
                                .read(chatRemoteDataSourceProvider)
                                .deleteChat(chat.id);
                            ref.invalidate(myChatsProvider);
                            if (context.mounted) {
                              AppToast.show(context, 'Chat deleted',
                                  type: ToastType.info);
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wave painter ────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.55);
    path.cubicTo(
      size.width * 0.25, size.height * 0.35,
      size.width * 0.55, size.height * 0.75,
      size.width, size.height * 0.50,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height * 0.70);
    path2.cubicTo(
      size.width * 0.30, size.height * 0.50,
      size.width * 0.65, size.height * 0.90,
      size.width, size.height * 0.65,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Wave header widget ───────────────────────────────────────────────────────
class _WaveHeader extends StatelessWidget {
  final double topPad;
  final AsyncValue<List<Chat>> chatsAsync;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;

  const _WaveHeader({
    required this.topPad,
    required this.chatsAsync,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF022C22), Color(0xFF065F46), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Wave
            const Positioned.fill(
              child: CustomPaint(painter: _WavePainter()),
            ),
            // Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      children: [
                        Builder(
                          builder: (ctx) => GestureDetector(
                            onTap: () => Scaffold.of(ctx).openDrawer(),
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.menu_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.location_on_rounded,
                                  color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 6),
                            Text('Find',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const Spacer(),
                        _HeaderIconBtn(
                          icon: Icons.search_rounded,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _HeaderIconBtn(
                          icon: Icons.notifications_outlined,
                          onTap: () {},
                          badge: 3,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 20),

                    // Title
                    Text('Messages',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.1))
                        .animate()
                        .fadeIn(delay: 80.ms, duration: 400.ms)
                        .slideX(begin: -0.06),
                    const SizedBox(height: 4),
                    chatsAsync.when(
                      data: (chats) => Text(
                        'Stay connected with your customers.',
                        style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 13),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ).animate().fadeIn(delay: 140.ms),

                    const SizedBox(height: 18),

                    // Search bar
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        style: GoogleFonts.outfit(fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                              'Search businesses, customers or messages...',
                          hintStyle: GoogleFonts.outfit(
                              color: Colors.grey[400], fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.grey[400], size: 20),
                          suffixIcon: const Icon(Icons.tune_rounded,
                              color: AppColors.primaryGreen, size: 20),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
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

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;
  const _HeaderIconBtn(
      {required this.icon, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$badge',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Category chips ─────────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final _ChatFilter selected;
  final ValueChanged<_ChatFilter> onSelected;

  const _CategoryChips(
      {required this.selected, required this.onSelected});

  static const _items = [
    (_ChatFilter.all, Icons.all_inclusive_rounded, 'All'),
    (_ChatFilter.customers, Icons.person_outline_rounded, 'Customers'),
    (_ChatFilter.businesses, Icons.storefront_outlined, 'Businesses'),
    (_ChatFilter.unread, Icons.mark_chat_unread_outlined, 'Unread'),
    (_ChatFilter.archived, Icons.archive_outlined, 'Archived'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(top: 14),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (filter, icon, label) = _items[i];
          final isSelected = selected == filter;
          return GestureDetector(
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGreen
                              .withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 15,
                      color:
                          isSelected ? Colors.white : Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color:
                          isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  if (filter == _ChatFilter.unread) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Chat card ────────────────────────────────────────────────────────────────
class _ChatCard extends ConsumerWidget {
  static const _productInquiryPrefix = 'IFIND_PRODUCT_INQUIRY::';

  final Chat chat;
  final int index;
  final VoidCallback onDelete;
  final bool isPinned;
  final int unreadCount;
  final bool isTyping;

  const _ChatCard({
    required this.chat,
    required this.index,
    required this.onDelete,
    this.isPinned = false,
    this.unreadCount = 0,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isB2B = chat.isB2B;
    final displayName = isB2B
        ? (chat.partnerBusinessName ?? 'B2B Partner')
        : (chat.businessName ?? chat.customerName ?? 'Customer');
    final displayLogo = isB2B
        ? chat.partnerBusinessLogo
        : (chat.businessLogoUrl ?? chat.customerAvatarUrl);
    final initials =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'B';
    final isBusiness = chat.businessId != null || isB2B;
    final preview = _previewMessage(chat.lastMessage);

    // Deterministic accent color per chat
    final accentColors = [
      AppColors.primaryGreen,
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];
    final accent = accentColors[math.Random(chat.id.hashCode).nextInt(accentColors.length)];

    return Dismissible(
      key: Key('chat_${chat.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent, size: 22),
      ),
      child: GestureDetector(
        onTap: () => context.push('/chat', extra: {
          'chat': chat,
          'otherPartyName': displayName,
        }),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isPinned
                    ? AppColors.primaryGreen.withValues(alpha: 0.45)
                    : Colors.grey.shade100,
                width: isPinned ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: isPinned
                    ? AppColors.primaryGreen.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + online dot
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: accent.withValues(alpha: 0.25),
                            width: 2),
                      ),
                      child: displayLogo != null
                          ? ClipOval(
                              child: Image.network(
                                displayLogo,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _initialsAvatar(initials, accent),
                              ),
                            )
                          : _initialsAvatar(initials, accent),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                    if (isPinned)
                      Positioned(
                        top: -4,
                        left: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.push_pin_rounded,
                              color: Colors.white, size: 9),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                ),
                                if (isBusiness) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                      Icons.verified_rounded,
                                      color: AppColors.primaryGreen,
                                      size: 15),
                                ],
                                if (isB2B) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen
                                          .withValues(alpha: 0.10),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text('B2B',
                                        style: GoogleFonts.outfit(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGreen,
                                        )),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (chat.lastMessageAt != null)
                            Text(
                              timeago.format(chat.lastMessageAt!,
                                  locale: 'en_short'),
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.grey[400]),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: isTyping
                                ? Row(
                                    children: [
                                      Text('Typing',
                                          style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  AppColors.primaryGreen)),
                                      const SizedBox(width: 6),
                                      const _TypingDots(),
                                    ],
                                  )
                                : Text(
                                    preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                      height: 1.3,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              constraints:
                                  const BoxConstraints(minWidth: 20),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 350.ms)
          .slideY(begin: 0.08),
    );
  }

  Widget _initialsAvatar(String initials, Color accent) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.outfit(
            color: accent,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  String _previewMessage(String? message) {
    if (message == null || message.trim().isEmpty) return 'No messages yet';
    if (message.startsWith(_productInquiryPrefix)) {
      try {
        final data = jsonDecode(
                message.substring(_productInquiryPrefix.length))
            as Map<String, dynamic>;
        final title = data['title'] as String? ?? 'product';
        return 'Product inquiry: $title';
      } catch (_) {
        return 'Product inquiry';
      }
    }
    if (message.startsWith('[MEDIA_INQUIRY]')) {
      final parts = message.split('|');
      if (parts.length > 3 && parts[3].trim().isNotEmpty) return parts[3];
      return 'Product inquiry';
    }
    return message;
  }
}

// ── Typing dots ──────────────────────────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 8,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final t = (_controller.value - (i * 0.2)) % 1.0;
              final scale = 0.5 + 0.5 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}