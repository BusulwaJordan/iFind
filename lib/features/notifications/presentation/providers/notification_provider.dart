import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:ifind/features/notifications/domain/entities/notification.dart';
import 'package:ifind/features/notifications/domain/repositories/notification_repository.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
export 'package:ifind/features/notifications/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(Supabase.instance.client);
});

final businessNotificationsProvider = StreamProvider.autoDispose.family<List<AppNotification>, String>((ref, businessId) {
  return ref.watch(notificationRepositoryProvider).watchNotifications(businessId);
});

final businessUnreadCountProvider = Provider.autoDispose.family<int, String>((ref, businessId) {
  final notifications = ref.watch(businessNotificationsProvider(businessId)).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  
  // Use myBusinessesStreamProvider since it's most responsive
  final myBusinesses = ref.watch(myBusinessesStreamProvider(user.id)).value ?? [];
  int totalCount = 0;
  for (final business in myBusinesses) {
    totalCount += ref.watch(businessUnreadCountProvider(business.id));
  }
  return totalCount;
});
