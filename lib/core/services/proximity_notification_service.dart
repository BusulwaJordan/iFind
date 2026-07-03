import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/services/proximity_service.dart';
import 'package:ifind/core/services/b2b_service.dart';

/// Checks for nearby high-compatibility businesses and writes proximity
/// notifications to the Supabase `notifications` table.
///
/// The existing [userNotificationsProvider] / [businessNotificationsProvider]
/// streams poll that table every 30 s, so users see the alert without FCM.
class ProximityNotificationService {
  final SupabaseClient _client;
  final ProximityService _proximityService;
  final B2bService _b2bService;

  /// Businesses already notified this session — avoids duplicate rows.
  final Set<String> _notified = {};

  /// Radius within which a nearby business triggers a notification.
  static const double _radiusKm = 1.0;

  /// Minimum B2B compatibility score to qualify as "high connection possibility".
  static const double _scoreThreshold = 0.75;

  ProximityNotificationService({
    required SupabaseClient client,
    required ProximityService proximityService,
    required B2bService b2bService,
  })  : _client = client,
        _proximityService = proximityService,
        _b2bService = b2bService;

  /// Run one proximity check for [myBusinessId] owned by [userId].
  ///
  /// Silently no-ops if location permission is denied or unavailable.
  Future<void> checkAndNotify({
    required String userId,
    required String myBusinessId,
  }) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final nearby = await _proximityService.getNearbyBusinesses(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: _radiusKm,
      );
      if (nearby.isEmpty) return;

      // One call ranks every business against myBusinessId — cheaper than a
      // pairwise request per nearby business, and matches the score shown
      // elsewhere in the app for the same pairing.
      final recommendations = await _b2bService.getRecommendations(myBusinessId, topN: 100);
      final scoreByBusinessId = {for (final r in recommendations) r.businessId: r.finalScore};

      for (final biz in nearby) {
        final targetId = biz['id'] as String?;
        if (targetId == null || targetId == myBusinessId) continue;

        // Deduplicate within this session.
        final key = '${myBusinessId}_$targetId';
        if (_notified.contains(key)) continue;

        final score = scoreByBusinessId[targetId];
        if (score == null || score < _scoreThreshold) continue;

        final rawDistanceM = (biz['distance_m'] as num?)?.toDouble() ?? 500.0;
        final distanceKm = rawDistanceM / 1000.0;
        final distanceLabel = '${distanceKm.toStringAsFixed(1)} km away';
        final bizName = biz['name'] as String? ?? 'A nearby business';

        await _writeNotification(
          userId: userId,
          businessId: myBusinessId,
          targetBusinessId: targetId,
          targetName: bizName,
          score: score,
          distanceLabel: distanceLabel,
        );

        _notified.add(key);
        debugPrint(
            'ProximityNotification: notified for $bizName (${(score * 100).round()}% match)');
      }
    } catch (e) {
      debugPrint('ProximityNotificationService error: $e');
    }
  }

  Future<void> _writeNotification({
    required String userId,
    required String businessId,
    required String targetBusinessId,
    required String targetName,
    required double score,
    required String distanceLabel,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'business_id': businessId,
      'type': 'proximity_match',
      'title': 'High-match business nearby!',
      'body':
          '$targetName is $distanceLabel — ${(score * 100).round()}% compatibility match.',
      'data': {
        'target_business_id': targetBusinessId,
        'score': score,
      },
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
