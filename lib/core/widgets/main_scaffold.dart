import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/notifications/presentation/providers/notification_provider.dart';
import 'package:ifind/features/notifications/domain/entities/notification.dart';
import 'package:ifind/features/notifications/utils/notification_preview_formatter.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  @override
  void initState() {
    super.initState();
    // Listen for notifications globally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationListener();
    });
  }

  void _setupNotificationListener() {
    // This will show a snackbar or custom popup when a new notification arrives
    // (Actual stream listening handled by riverpod but we can trigger UI effects here)
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show welcome toast after login/register
    ref.listen(loginWelcomeProvider, (_, next) {
      if (next != null && mounted) {
        AppToast.show(context, next, type: ToastType.success);
        ref.read(loginWelcomeProvider.notifier).state = null;
      }
    });

    // Listen to real-time notification stream for custom toasts
    ref.listen(userNotificationsProvider, (previous, next) {
      final notificationsEnabled =
          ref.read(notificationSettingsProvider).value ?? true;
      if (!notificationsEnabled) return;

      final oldNotifications = previous?.value ?? [];
      final newNotifications = next.value ?? [];

      if (newNotifications.length > oldNotifications.length) {
        final newlyAdded = newNotifications
            .where((n) =>
                !n.isRead && !oldNotifications.any((oldN) => oldN.id == n.id))
            .toList();

        for (final notification in newlyAdded) {
          _showPremiumNotificationToast(context, notification);
        }
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: widget.navigationShell,
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.explore_rounded, 'Discover'),
                  _buildNavItem(2, Icons.chat_bubble_rounded, 'Chat'),
                  _buildNavItem(3, Icons.handshake_rounded, 'B2B'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = widget.navigationShell.currentIndex == index;
    final color = isSelected ? AppColors.primaryGreen : Colors.grey[500];

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(index),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryGreen.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: isSelected ? 24 : 22,
              ).animate(target: isSelected ? 1 : 0).scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1.0, 1.0),
                    duration: 250.ms,
                  ),
              if (isSelected) ...[
                const SizedBox(height: 3),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(duration: 150.ms).slideY(begin: 5, end: 0)
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPremiumNotificationToast(
      BuildContext context, AppNotification notification) {
    IconData iconData;
    Color iconColor;
    VoidCallback onTapAction;
    String actionLabel;
    final previewBody =
        NotificationPreviewFormatter.cleanBody(notification.body);

    switch (notification.type) {
      case 'chat':
        iconData = Icons.chat_bubble_rounded;
        iconColor = Colors.blue;
        actionLabel = 'CHAT';
        onTapAction = () {
          _onTap(2); // Chat list tab
        };
        break;
      case 'b2b_match':
        iconData = Icons.handshake_rounded;
        iconColor = Colors.amber.shade700;
        actionLabel = 'VIEW';
        onTapAction = () {
          _onTap(3); // Shop tab (B2B Leads/Matches)
        };
        break;
      case 'need_match':
        iconData = Icons.local_offer_rounded;
        iconColor = AppColors.primaryGreen;
        actionLabel = 'LEADS';
        onTapAction = () {
          _onTap(3); // Shop tab (Customer leads)
        };
        break;
      default:
        iconData = Icons.notifications_active_rounded;
        iconColor = AppColors.deepGreen;
        actionLabel = 'OPEN';
        onTapAction = () {
          context.push('/notifications');
        };
    }

    AppToast.showNotification(
      context,
      title: notification.title,
      body: previewBody,
      icon: iconData,
      color: iconColor,
      actionLabel: actionLabel,
      onAction: onTapAction,
    );
  }
}
