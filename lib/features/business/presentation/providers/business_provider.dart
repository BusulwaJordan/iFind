import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/features/auth/domain/entities/user.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:ifind/core/services/storage_service.dart';
import 'package:ifind/features/business/data/datasources/business_remote_datasource.dart';
import 'package:ifind/features/business/data/repositories/business_repository_impl.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/domain/repositories/business_repository.dart';
import 'package:ifind/features/business/domain/usecases/get_nearby_businesses.dart';
import 'package:geolocator/geolocator.dart';

// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});

// Data Source Provider
final businessRemoteDataSourceProvider =
    Provider<BusinessRemoteDataSource>((ref) {
  return BusinessRemoteDataSource(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

// Repository Provider
final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepositoryImpl(
    remoteDataSource: ref.watch(businessRemoteDataSourceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

// Use Case Providers
final getNearbyBusinessesProvider = Provider<GetNearbyBusinesses>((ref) {
  return GetNearbyBusinesses(ref.watch(businessRepositoryProvider));
});

// State Providers for Filtering
final selectedCategoryProvider =
    StateProvider<BusinessCategory?>((ref) => null);
final searchRadiusProvider = StateProvider<double>((ref) => 15.0); // km
final searchQueryProvider = StateProvider<String>((ref) => '');

// Business List Logic
class BusinessListNotifier extends StateNotifier<AsyncValue<List<Business>>> {
  final GetNearbyBusinesses getNearbyBusinesses;
  final double radius;
  final BusinessCategory? category;
  final Ref ref;

  BusinessListNotifier({
    required this.getNearbyBusinesses,
    required this.radius,
    required this.ref,
    this.category,
  }) : super(const AsyncValue.loading()) {
    loadBusinesses();
  }

  Future<void> loadBusinesses() async {
    state = const AsyncValue.loading();

    // Default: Kampala center
    double latitude = 0.3476;
    double longitude = 32.5825;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition();
          latitude = position.latitude;
          longitude = position.longitude;
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e. Falling back to default.');
    }

    final result = await getNearbyBusinesses(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radius,
      category: category,
    );

    result.fold(
      (failure) {
        // Show actual error instead of hiding with mock data
        debugPrint('Failed to load businesses: ${failure.message}');
        state = AsyncValue.error(
          'Failed to load businesses: ${failure.message}. Check database connection and RPC function.',
          StackTrace.current,
        );
      },
      (businesses) {
        // Filter out current user's own businesses
        final currentUser = ref.read(currentUserProvider);
        var filtered = businesses;
        if (currentUser != null) {
          filtered =
              businesses.where((b) => b.ownerId != currentUser.id).toList();
        }
        // Search-query filtering happens in filteredBusinessesProvider below,
        // purely in-memory over this fetched list — not here, so typing a
        // search query never re-triggers a location/network fetch.
        state = AsyncValue.data(filtered);
      },
    );
  }
}

// Business List Provider
final nearbyBusinessesProvider = StateNotifierProvider.autoDispose<
    BusinessListNotifier, AsyncValue<List<Business>>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final radius = ref.watch(searchRadiusProvider);

  return BusinessListNotifier(
    getNearbyBusinesses: ref.watch(getNearbyBusinessesProvider),
    radius: radius,
    category: category,
    ref: ref,
  );
});

/// nearbyBusinessesProvider's list, filtered in-memory by searchQueryProvider
/// as the user types — no network refetch per keystroke, since the search
/// query never changes location/radius/category.
final filteredBusinessesProvider =
    Provider.autoDispose<AsyncValue<List<Business>>>((ref) {
  final businessesAsync = ref.watch(nearbyBusinessesProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return businessesAsync;

  return businessesAsync.whenData((businesses) => businesses
      .where((b) =>
          b.name.toLowerCase().contains(query) ||
          b.description.toLowerCase().contains(query))
      .toList());
});

final featuredBusinessesProvider = FutureProvider<List<Business>>((ref) async {
  final repository = ref.watch(businessRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);

  final result = await repository.getFeaturedBusinesses();
  return result.fold(
    (failure) => [],
    (businesses) {
      // Filter out current user's own businesses
      if (currentUser != null) {
        return businesses.where((b) => b.ownerId != currentUser.id).toList();
      }
      return businesses;
    },
  );
});

final myBusinessesProvider =
    FutureProvider.family<List<Business>, String>((ref, ownerId) async {
  final repository = ref.watch(businessRepositoryProvider);
  final result = await repository.getMyBusinesses(ownerId);
  return result.fold(
    (failure) => [],
    (businesses) => businesses,
  );
});

final businessProvider =
    FutureProvider.family<Business?, String>((ref, businessId) async {
  final repository = ref.watch(businessRepositoryProvider);
  final result = await repository.getBusinessById(businessId);
  return result.fold(
    (failure) => null,
    (business) => business,
  );
});

final businessStreamProvider =
    StreamProvider.family<Business?, String>((ref, businessId) {
  final repository = ref.watch(businessRepositoryProvider);
  return repository.watchBusiness(businessId);
});

final myBusinessesStreamProvider =
    StreamProvider.family<List<Business>, String>((ref, ownerId) {
  final repository = ref.watch(businessRepositoryProvider);
  return repository.watchMyBusinesses(ownerId);
});

/// Returns whether the current business owner has at least one shop set up.
/// Non-business-owners always return data(true) so the router guard is a no-op for them.
final ownerHasShopProvider = Provider<AsyncValue<bool>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.role != UserRole.businessOwner) {
    return const AsyncValue.data(true);
  }
  final businessesAsync = ref.watch(myBusinessesStreamProvider(user.id));
  return businessesAsync.when(
    data: (businesses) => AsyncValue.data(businesses.isNotEmpty),
    loading: () => const AsyncValue.loading(),
    error: (_, __) => const AsyncValue.data(true), // fail open — don't block on error
  );
});
