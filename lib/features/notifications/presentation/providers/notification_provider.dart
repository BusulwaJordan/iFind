import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:ifind/features/notifications/domain/entities/notification.dart';
import 'package:ifind/features/notifications/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(Supabase.instance.client);
});

final businessNotificationsProvider = StreamProvider.autoDispose.family<List<AppNotification>, String>((ref, businessId) {
  return ref.watch(notificationRepositoryProvider).watchNotifications(businessId);
});

final unreadNotificationCountProvider = Provider.autoDispose.family<int, String>((ref, businessId) {
  final notifications = ref.watch(businessNotificationsProvider(businessId)).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});
