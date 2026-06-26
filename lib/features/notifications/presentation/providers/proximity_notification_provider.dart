import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/core/providers/ai_providers.dart';
import 'package:ifind/core/services/proximity_notification_service.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';

final proximityNotificationServiceProvider =
    Provider<ProximityNotificationService>((ref) {
  return ProximityNotificationService(
    client: ref.watch(supabaseClientProvider),
    proximityService: ref.watch(proximityServiceProvider),
    b2bService: ref.watch(b2bServiceProvider),
  );
});

/// Starts a periodic proximity check every 5 minutes while the provider is
/// alive. Wire this into the main scaffold with [ref.watch] so it runs
/// whenever a business owner is logged in.
///
/// Usage in a ConsumerWidget:
///   ref.watch(proximityNotificationWatcherProvider);
final proximityNotificationWatcherProvider = StreamProvider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  final myBusinessesAsync = ref.watch(myBusinessesProvider(user?.id ?? ''));
  final business = myBusinessesAsync.value?.firstOrNull;

  // Only run for business owners who have a business profile.
  if (user == null || business == null) {
    return const Stream.empty();
  }

  final service = ref.watch(proximityNotificationServiceProvider);

  final controller = StreamController<void>();

  Future<void> runCheck() async {
    await service.checkAndNotify(
      userId: user.id,
      myBusinessId: business.id,
      myCategory: business.category.storageValue,
    );
    if (!controller.isClosed) controller.add(null);
  }

  // Run immediately then every 5 minutes.
  runCheck();
  final timer = Timer.periodic(const Duration(minutes: 5), (_) => runCheck());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
