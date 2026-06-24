import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/notifications/presentation/providers/notification_provider.dart';
import 'package:ifind/features/notifications/domain/entities/notification.dart';
import 'package:ifind/features/notifications/utils/notification_preview_formatter.dart';

class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final User? user;

  const MainScaffold({
    super.key,
    required this.navigationShell,
    this.user,
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
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navigationShell.currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        elevation: 8,
        items: _getNavItems(isBusinessOwner),
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }

  List<BottomNavigationBarItem> _getNavItems(bool isBusinessOwner) {
    if (isBusinessOwner) {
      // Business Owner Nav: Dashboard | Discover | Chats | My Shop
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Discover',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.chat_outlined),
          activeIcon: Icon(Icons.chat),
          label: 'Chats',
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