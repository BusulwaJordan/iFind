import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/core/providers/ai_providers.dart';
import 'package:ifind/core/services/b2b_service.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'dart:math';

final b2bPartnerCandidatesProvider =
    FutureProvider.family<List<Business>, Business>((ref, business) async {
  final repository = ref.watch(businessRepositoryProvider);
  final result = await repository.getNearbyBusinesses(
    latitude: business.latitude,
    longitude: business.longitude,
    radiusKm: 30,
  );

  return result.fold(
    (failure) => <Business>[],
    (businesses) {
      final candidates = businesses
          .where((candidate) =>
              candidate.id != business.id &&
              candidate.ownerId != business.ownerId &&
              candidate.isVerified)
          .toList();

      candidates.sort((a, b) {
        final distanceCompare = (a.distance ?? double.infinity)
            .compareTo(b.distance ?? double.infinity);
        if (distanceCompare != 0) return distanceCompare;
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return b.reviewCount.compareTo(a.reviewCount);
      });

      return candidates.take(10).toList();
    },
  );
});

/// Provider that computes B2B compatibility between the currently-viewed
/// business [targetBusiness] and the current user's own business [myBusiness].
///
/// Uses the custom Random Forest model via the `b2b-match` Edge Function.
final b2bCompatibilityProvider = FutureProvider.family<B2bCompatibilityResult,
    ({Business myBusiness, Business targetBusiness})>((ref, args) async {
  final service = ref.watch(b2bServiceProvider);

  // Calculate distance between the two businesses
  final distanceKm = _haversineDistanceKm(
    args.myBusiness.latitude,
    args.myBusiness.longitude,
    args.targetBusiness.latitude,
    args.targetBusiness.longitude,
  );

  return service.getCompatibilityScore(
    categoryA: args.myBusiness.category.name,
    categoryB: args.targetBusiness.category.name,
    distanceKm: distanceKm,
  );
});

/// Haversine formula — great-circle distance between two lat/lng points (km).
double _haversineDistanceKm(
    double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0; // Earth radius in km
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double _deg2rad(double deg) => deg * (pi / 180);
