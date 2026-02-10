import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/loading_widget.dart';
import 'package:ifind/features/notifications/presentation/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  final String businessId;

  const NotificationsScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(businessNotificationsProvider(businessId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ).animate().fadeIn(),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: Key(notification.id),
                background: Container(color: Colors.red),
                onDismissed: (_) {
                  // TODO: Implement delete
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  tileColor: notification.isRead ? Colors.white : AppColors.primaryGreen.withValues(alpha: 0.05),
                  leading: CircleAvatar(
                    backgroundColor: notification.isRead ? Colors.grey[200] : AppColors.primaryGreen,
                    child: Icon(
                      Icons.notifications,
                      color: notification.isRead ? Colors.grey : Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: GoogleFonts.outfit(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notification.body, style: GoogleFonts.outfit()),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(notification.createdAt),
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Mark as read
                    ref.read(notificationRepositoryProvider).markAsRead(notification.id);
                    // Navigate if needed (e.g. to specific need)
                  },
                ).animate().fadeIn(delay: (index * 50).ms).slideX(),
              );
            },
          );
        },
      ),
    );
  }
}
