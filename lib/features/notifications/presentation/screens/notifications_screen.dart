import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/loading_widget.dart';
import 'package:ifind/core/widgets/error_retry_widget.dart';
import 'package:ifind/core/utils/error_utils.dart';
import 'package:ifind/features/notifications/presentation/providers/notification_provider.dart';
import 'package:ifind/features/notifications/domain/entities/notification.dart';
import 'package:ifind/features/notifications/utils/notification_preview_formatter.dart';

class NotificationsScreen extends ConsumerWidget {
  final String? businessId;

  const NotificationsScreen({super.key, this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = businessId != null
        ? ref.watch(businessNotificationsProvider(businessId!))
        : ref.watch(userNotificationsProvider);

    final unreadCount = notificationsAsync.value
            ?.where((n) => !n.isRead)
            .length ??
        0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.deepGreen,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            actions: [
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: () async {
                    final notifications = notificationsAsync.value ?? [];
                    final repo = ref.read(notificationRepositoryProvider);
                    for (final n in notifications.where((n) => !n.isRead)) {
                      await repo.markAsRead(n.id);
                    }
                    _refreshNotifications(ref, businessId: businessId);
                    if (context.mounted) {
                      AppToast.show(context, 'All marked as read',
                          type: ToastType.success);
                    }
                  },
                  icon: const Icon(Icons.done_all_rounded,
                      color: Colors.white70, size: 18),
                  label: Text('Mark all read',
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 13)),
                ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.deepGreen, AppColors.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.notifications_rounded,
                                  color: Colors.white,
                                  size: 24),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notifications',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (unreadCount > 0)
                                  Text(
                                    '$unreadCount unread',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          notificationsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: LoadingWidget()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(
                child: ErrorRetryWidget(
                  message: friendlyError(err),
                  onRetry: () =>
                      _refreshNotifications(ref, businessId: businessId),
                ),
              ),
            ),
            data: (notifications) {
              if (notifications.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.notifications_none_rounded,
                              size: 64, color: Colors.grey.shade300),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'All caught up!',
                          style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'New messages, B2B matches,\nand leads will appear here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _NotificationCard(
                      notification: notifications[index],
                      index: index,
                      businessId: businessId,
                    ),
                    childCount: notifications.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Notification card ────────────────────────────────────────────────────────

class _NotificationCard extends ConsumerWidget {
  final AppNotification notification;
  final int index;
  final String? businessId;

  const _NotificationCard({
    required this.notification,
    required this.index,
    this.businessId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewBody =
        NotificationPreviewFormatter.cleanBody(notification.body);

    final (iconData, themeColor, typeLabel) = switch (notification.type) {
      'chat' => (Icons.chat_bubble_rounded, Colors.blue, 'Message'),
      'b2b_match' => (Icons.handshake_rounded, Colors.amber.shade700, 'B2B Match'),
      'need_match' => (
          Icons.local_offer_rounded,
          AppColors.primaryGreen,
          'Lead Alert'
        ),
      _ => (
          Icons.notifications_rounded,
          AppColors.deepGreen,
          'System'
        ),
    };

    return Dismissible(
      key: Key('notif_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent.shade400, size: 26),
      ),
      onDismissed: (_) async {
        await ref
            .read(notificationRepositoryProvider)
            .deleteNotification(notification.id);
        _refreshNotifications(ref, businessId: businessId);
        if (context.mounted) {
          AppToast.show(context, 'Notification removed',
              type: ToastType.info);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade100
                : themeColor.withValues(alpha: 0.25),
            width: notification.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () async {
              if (!notification.isRead) {
                await ref
                    .read(notificationRepositoryProvider)
                    .markAsRead(notification.id);
                _refreshNotifications(ref, businessId: businessId);
              }
              final route = switch (notification.type) {
                'chat' => '/chats',
                'need_match' || 'b2b_match' => '/my-shop',
                _ => null,
              };
              if (route != null && context.mounted) context.go(route);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon circle
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: themeColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                typeLabel.toUpperCase(),
                                style: GoogleFonts.outfit(
                                    color: themeColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timeago.format(notification.createdAt),
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification.title,
                                    style: GoogleFonts.outfit(
                                      fontWeight: notification.isRead
                                          ? FontWeight.w600
                                          : FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    previewBody,
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin:
                                    const EdgeInsets.only(left: 8, top: 6),
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  shape: BoxShape.circle,
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
        ),
      ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.05, end: 0),
    );
  }
}

void _refreshNotifications(WidgetRef ref, {String? businessId}) {
  ref.invalidate(userNotificationsProvider);
  if (businessId != null) {
    ref.invalidate(businessNotificationsProvider(businessId));
  }
}
