import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/loading_widget.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.wifi_off_rounded,
                      size: 48, color: Colors.orange.shade700),
                ),
                const SizedBox(height: 18),
                Text(
                  'Notifications could not load',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () =>
                      _refreshNotifications(ref, businessId: businessId),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_none_rounded,
                        size: 64, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'All caught up!',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New messages, B2B matches, and leads will appear here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ).animate().fadeIn(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(
                notification: notification,
                index: index,
                businessId: businessId,
              );
            },
          );
        },
      ),
    );
  }
}

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
    IconData iconData;
    Color themeColor;
    String typeLabel;
    final previewBody =
        NotificationPreviewFormatter.cleanBody(notification.body);

    switch (notification.type) {
      case 'chat':
        iconData = Icons.chat_bubble_rounded;
        themeColor = Colors.blue;
        typeLabel = 'Chat';
        break;
      case 'b2b_match':
        iconData = Icons.handshake_rounded;
        themeColor = Colors.amber.shade700;
        typeLabel = 'B2B Match';
        break;
      case 'need_match':
        iconData = Icons.local_offer_rounded;
        themeColor = AppColors.primaryGreen;
        typeLabel = 'Lead Alert';
        break;
      default:
        iconData = Icons.notifications_rounded;
        themeColor = AppColors.deepGreen;
        typeLabel = 'System';
    }

    return Dismissible(
      key: Key('notif_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade100.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent.shade400, size: 28),
      ),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        await ref
            .read(notificationRepositoryProvider)
            .deleteNotification(notification.id);
        _refreshNotifications(ref, businessId: businessId);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Notification deleted', style: GoogleFonts.outfit()),
            backgroundColor: Colors.grey.shade900,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade200
                : themeColor.withValues(alpha: 0.3),
            width: notification.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () async {
              final route = switch (notification.type) {
                'chat' => '/chats',
                'need_match' || 'b2b_match' => '/my-shop',
                _ => null,
              };

              // Mark as read
              if (!notification.isRead) {
                await ref
                    .read(notificationRepositoryProvider)
                    .markAsRead(notification.id);
                _refreshNotifications(ref, businessId: businessId);
              }

              // Route contextually
              if (route != null && context.mounted) {
                context.go(route);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: themeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
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
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              timeago.format(notification.createdAt),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
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
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    previewBody,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8, top: 4),
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
      ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05, end: 0),
    );
  }
}

void _refreshNotifications(WidgetRef ref, {String? businessId}) {
  ref.invalidate(userNotificationsProvider);
  if (businessId != null) {
    ref.invalidate(businessNotificationsProvider(businessId));
  }
}
