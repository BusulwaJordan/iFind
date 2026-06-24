import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/business/domain/entities/business.dart';

/// MODEL 1: Proximity Search (PostGIS)
///
/// Calls the `get_nearby_businesses` RPC function already defined in Supabase.
/// No ML — pure SQL using ST_DWithin on the PostGIS `location` column.
///
/// This service is a lightweight wrapper around the Supabase RPC call so that
/// providers can depend on it without knowing about Supabase directly.
class ProximityService {
  final SupabaseClient _client;

  ProximityService(this._client);

  /// Returns businesses within [radiusKm] of [latitude]/[longitude].
  ///
  /// Optionally filters by [category] (matches the `category` TEXT column).
  /// Results are sorted by distance ascending (closest first).
  ///
  /// Falls back to an empty list on error, and logs the failure for debugging.
  Future<List<Map<String, dynamic>>> getNearbyBusinesses({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    BusinessCategory? category,
  }) async {
    try {
      final params = <String, dynamic>{
        'lat': latitude,
        'long': longitude,
        'radius_km': radiusKm,
        if (category != null) 'category_filter': category.storageValue,
      };

      debugPrint('ProximityService: Calling get_nearby_businesses RPC...');

      final List<dynamic> response = await _client.rpc(
        'get_nearby_businesses',
        params: params,
      );

      debugPrint('ProximityService: Got ${response.length} businesses.');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('ProximityService Error: $e');
      return [];
    }
  }

  /// Convenience method: returns the raw JSON as a pretty-printed string.
  /// Useful for debugging in dev mode.
  Future<String> getNearbyBusinessesJson({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    BusinessCategory? category,
  }) async {
    final results = await getNearbyBusinesses(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      category: category,
    );
    return const JsonEncoder.withIndent('  ').convert(results);
  }
}
