import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';

class FavouritesNotifier extends AsyncNotifier<Set<String>> {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Set<String>> build() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    final response = await _client
        .from('favorites')
        .select('business_id')
        .eq('user_id', user.id);

    return (response as List)
        .map((r) => r['business_id'] as String)
        .toSet();
  }

  Future<void> toggle(String businessId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final current = state.valueOrNull ?? {};

    if (current.contains(businessId)) {
      // Optimistic remove
      state = AsyncData(current.difference({businessId}));
      try {
        await _client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('business_id', businessId);
      } catch (_) {
        state = AsyncData(current);
      }
    } else {
      // Optimistic add
      state = AsyncData({...current, businessId});
      try {
        await _client.from('favorites').upsert({
          'user_id': user.id,
          'business_id': businessId,
        });
      } catch (_) {
        state = AsyncData(current);
      }
    }
  }
}

final favouritesProvider =
    AsyncNotifierProvider<FavouritesNotifier, Set<String>>(
  FavouritesNotifier.new,
);

final savedBusinessesProvider =
    FutureProvider.autoDispose<List<Business>>((ref) async {
  final ids = ref.watch(favouritesProvider).valueOrNull ?? {};
  if (ids.isEmpty) return [];

  final repository = ref.watch(businessRepositoryProvider);
  final futures = ids.map((id) => repository.getBusinessById(id));
  final results = await Future.wait(futures);

  final businesses = <Business>[];
  for (final either in results) {
    either.fold((_) {}, (b) => businesses.add(b));
  }
  return businesses;
});
