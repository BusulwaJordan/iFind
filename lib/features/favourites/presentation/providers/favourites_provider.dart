import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';

const _prefsKey = 'saved_business_ids';

class FavouritesNotifier extends StateNotifier<Set<String>> {
  FavouritesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKey) ?? [];
    state = ids.toSet();
  }

  Future<void> toggle(String businessId) async {
    final updated = Set<String>.from(state);
    if (updated.contains(businessId)) {
      updated.remove(businessId);
    } else {
      updated.add(businessId);
    }
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, updated.toList());
  }

  bool isSaved(String businessId) => state.contains(businessId);
}

final favouritesProvider =
    StateNotifierProvider<FavouritesNotifier, Set<String>>(
  (ref) => FavouritesNotifier(),
);

final savedBusinessesProvider =
    FutureProvider.autoDispose<List<Business>>((ref) async {
  final ids = ref.watch(favouritesProvider);
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
