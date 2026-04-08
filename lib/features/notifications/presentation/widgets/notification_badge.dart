import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/notifications/presentation/providers/notification_provider.dart';
import 'package:badges/badges.dart' as badges;

class NotificationBadge extends ConsumerWidget {
  final String businessId;
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.businessId,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(businessUnreadCountProvider(businessId));

    return badges.Badge(
      position: badges.BadgePosition.topEnd(top: 0, end: 0),
      showBadge: unreadCount > 0,
      badgeContent: Text(
        unreadCount > 99 ? '99+' : unreadCount.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      badgeStyle: const badges.BadgeStyle(
        badgeColor: AppColors.error,
        padding: EdgeInsets.all(4),
      ),
      child: child,
    );
  }
}
