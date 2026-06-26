import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/widgets/app_toast.dart';
import 'package:ifind/core/widgets/ifind_loader.dart';
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
    if (user == null) return const IFindLoadingPage();

    final isBusinessOwner = user.role == UserRole.businessOwner;
    final currentIndex = widget.navigationShell.currentIndex;

    ref.listen(loginWelcomeProvider, (_, next) {
      if (next != null && mounted) {
        AppToast.show(context, next, type: ToastType.success);
        ref.read(loginWelcomeProvider.notifier).state = null;
      }
    });

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _buildFAB(context),
        bottomNavigationBar: _buildNotchedBar(isBusinessOwner, currentIndex),
        body: widget.navigationShell,
      ),
    );
  }

  // ── Center FAB ────────────────────────────────────────────────────────────

  Widget _buildFAB(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.deepGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.50),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.deepGreen.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onTap(2),
          child: const Center(
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  // ── Notched BottomAppBar ──────────────────────────────────────────────────

  Widget _buildNotchedBar(bool isBusinessOwner, int currentIndex) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      padding: EdgeInsets.zero,
      height: 72,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      color: Colors.white,
      child: Row(
        children: [
          // ── Left 2 items ──────────────────────────────────────────────
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: isBusinessOwner
                  ? [
                      _NavItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        isSelected: currentIndex == 0,
                        onTap: () => _onTap(0),
                      ),
                      _NavItem(
                        icon: Icons.search_outlined,
                        activeIcon: Icons.search_rounded,
                        label: 'Discover',
                        isSelected: currentIndex == 1,
                        onTap: () => _onTap(1),
                      ),
                    ]
                  : [
                      _NavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Home',
                        isSelected: currentIndex == 0,
                        onTap: () => _onTap(0),
                      ),
                      _NavItem(
                        icon: Icons.search_outlined,
                        activeIcon: Icons.search_rounded,
                        label: 'Discover',
                        isSelected: currentIndex == 1,
                        onTap: () => _onTap(1),
                      ),
                    ],
            ),
          ),

          // ── Center gap (FAB sits here) ────────────────────────────────
          const SizedBox(width: 80),

          // ── Right 2 items ─────────────────────────────────────────────
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: isBusinessOwner
                  ? [
                      _NavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        activeIcon: Icons.chat_bubble_rounded,
                        label: 'Chats',
                        isSelected: currentIndex == 3,
                        onTap: () => _onTap(3),
                      ),
                      _NavItem(
                        icon: Icons.storefront_outlined,
                        activeIcon: Icons.storefront_rounded,
                        label: 'My Shop',
                        isSelected: currentIndex == 4,
                        onTap: () => _onTap(4),
                      ),
                    ]
                  : [
                      _NavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        activeIcon: Icons.chat_bubble_rounded,
                        label: 'Chats',
                        isSelected: currentIndex == 3,
                        onTap: () => _onTap(3),
                      ),
                      _NavItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Profile',
                        isSelected: currentIndex == 4,
                        onTap: () => _onTap(4),
                      ),
                    ],
            ),
          ),
        ],
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
        onTapAction = () => _onTap(3);
        break;
      case 'b2b_match':
        iconData = Icons.handshake_rounded;
        iconColor = Colors.amber.shade700;
        actionLabel = 'VIEW';
        onTapAction = () => _onTap(4);
        break;
      case 'need_match':
        iconData = Icons.local_offer_rounded;
        iconColor = AppColors.primaryGreen;
        actionLabel = 'LEADS';
        onTapAction = () => _onTap(4);
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

// ── Nav item widget ───────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                size: 24,
                color: isSelected
                    ? AppColors.primaryGreen
                    : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 3),

            // Label (shown when selected)
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: GoogleFonts.outfit(
                fontSize: isSelected ? 10.5 : 0.1,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.deepGreen
                    : Colors.transparent,
                height: 1,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.clip),
            ),

            const SizedBox(height: 4),

            // Underline indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: isSelected ? 22 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
