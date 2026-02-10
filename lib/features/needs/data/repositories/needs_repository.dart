import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/needs/domain/entities/need.dart';

class NeedsRepository {
  final SupabaseClient _client;

  NeedsRepository(this._client);

  Future<void> createNeed(Need need) async {
    await _client.from('needs').insert(need.toJson());
  }

  Stream<List<Need>> watchMyNeeds(String userId) {
    return _client
        .from('needs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((data) => data.map((json) => Need.fromJson(json)).toList());
  }

  Future<List<Need>> getNearbyNeeds(double lat, double long, double radiusKm) async {
    // For MVP, we'll fetch active needs and filter in Dart.
    // In production, use PostGIS for efficient geo-queries.
    final response = await _client
        .from('needs')
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false);

    final needs = (response as List).map((json) => Need.fromJson(json)).toList();
    
    // Simple filter (approximate)
    return needs.where((need) {
      // TODO: Implement Haversine distance check here
      return true; // Return all for now to verify UI
    }).toList();
  }
}
