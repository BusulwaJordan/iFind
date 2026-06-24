import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/notifications/presentation/providers/notification_provider.dart';
import 'package:ifind/features/notifications/domain/entities/notification.dart';
import 'package:ifind/features/notifications/utils/notification_preview_formatter.dart';

class MainScaffold extends ConsumerStatefulWidget {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationListener();
    });
  }

  void _setupNotificationListener() {}

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

    final isBusinessOwner = user.role == UserRole.businessOwner;

    // Show welcome toast after login/register
    ref.listen(loginWelcomeProvider, (_, next) {
      if (next != null && mounted) {
        AppToast.show(context, next, type: ToastType.success);
        ref.read(loginWelcomeProvider.notifier).state = null;
      }
    });

    // Show in-app toast when a new notification arrives
    ref.listen(userNotificationsProvider, (previous, next) {
      final notificationsEnabled =
          ref.read(notificationSettingsProvider).value ?? true;
      if (!notificationsEnabled) return;

      final oldNotifications = previous?.value ?? [];
      final newNotifications = next.value ?? [];

      if (newNotifications.length > oldNotifications.length) {
        final newlyAdded = newNotifications
            .where((n) =>
                !n.isRead && !oldNotifications.any((old) => old.id == n.id))
            .toList();

        for (final notification in newlyAdded) {
          _showPremiumNotificationToast(context, notification);
        }
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: widget.navigationShell,
      bottomNavigationBar: _buildFloatingNavBar(isBusinessOwner),
    );
  }

  Widget _buildFloatingNavBar(bool isBusinessOwner) {
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
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: widget.navigationShell.currentIndex,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primaryGreen,
            unselectedItemColor: Colors.grey[500],
            selectedLabelStyle: GoogleFonts.outfit(
                fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                GoogleFonts.outfit(fontSize: 11),
            showUnselectedLabels: true,
            elevation: 0,
            items: isBusinessOwner
                ? const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_outlined),
                      activeIcon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search_outlined),
                      activeIcon: Icon(Icons.search),
                      label: 'Discover',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat_bubble_outline_rounded),
                      activeIcon: Icon(Icons.chat_bubble_rounded),
                      label: 'Chats',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.storefront_outlined),
                      activeIcon: Icon(Icons.storefront_rounded),
                      label: 'My Shop',
                    ),
                  ]
                : const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search_outlined),
                      activeIcon: Icon(Icons.search),
                      label: 'Discover',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat_bubble_outline_rounded),
                      activeIcon: Icon(Icons.chat_bubble_rounded),
                      label: 'Chats',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline_rounded),
                      activeIcon: Icon(Icons.person_rounded),
                      label: 'Profile',
                    ),
                  ],
            onTap: _onTap,
          ),
        ),
      ),
    );
  }

  void _showPremiumNotificationToast(
      BuildContext context, AppNotification notification) {
    final previewBody =
        NotificationPreviewFormatter.cleanBody(notification.body);

    IconData iconData;
    Color iconColor;
    VoidCallback onTapAction;
    String actionLabel;

    switch (notification.type) {
      case 'chat':
        iconData = Icons.chat_bubble_rounded;
        iconColor = Colors.blue;
        actionLabel = 'CHAT';
        onTapAction = () => _onTap(2);
        break;
      case 'b2b_match':
        iconData = Icons.handshake_rounded;
        iconColor = Colors.amber.shade700;
        actionLabel = 'VIEW';
        onTapAction = () => _onTap(3);
        break;
      case 'need_match':
        iconData = Icons.local_offer_rounded;
        iconColor = AppColors.primaryGreen;
        actionLabel = 'LEADS';
        onTapAction = () => _onTap(3);
        break;
      default:
        iconData = Icons.notifications_active_rounded;
        iconColor = AppColors.deepGreen;
        actionLabel = 'OPEN';
        onTapAction = () => context.push('/notifications');
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
