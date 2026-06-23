import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:ifind/features/notifications/domain/entities/notification.dart';
import 'package:ifind/features/notifications/domain/repositories/notification_repository.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
export 'package:ifind/features/notifications/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(Supabase.instance.client);
});

class NotificationSettingsNotifier extends StateNotifier<AsyncValue<bool>> {
  NotificationSettingsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  static const _key = 'notifications_enabled';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AsyncValue.data(prefs.getBool(_key) ?? true);
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncValue.data(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, AsyncValue<bool>>(
  (ref) => NotificationSettingsNotifier(),
);

final businessNotificationsProvider = StreamProvider.autoDispose
    .family<List<AppNotification>, String>((ref, businessId) {
  final enabled = ref.watch(notificationSettingsProvider).value ?? true;
  if (!enabled) return Stream.value([]);
  return ref
      .watch(notificationRepositoryProvider)
      .watchNotifications(businessId);
});

final businessUnreadCountProvider =
    Provider.autoDispose.family<int, String>((ref, businessId) {
  final notifications =
      ref.watch(businessNotificationsProvider(businessId)).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

final userNotificationsProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final enabled = ref.watch(notificationSettingsProvider).value ?? true;
  if (!enabled) return Stream.value([]);
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref
      .watch(notificationRepositoryProvider)
      .watchUserNotifications(user.id);
});

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(userNotificationsProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});
