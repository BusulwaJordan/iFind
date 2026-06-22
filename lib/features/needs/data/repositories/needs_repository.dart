import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/utils/distance_calculator.dart';
import 'package:ifind/features/needs/domain/entities/need.dart';

class NeedsRepository {
  final SupabaseClient _client;

  NeedsRepository(this._client);

  Future<String> createNeed(Need need) async {
    final response =
        await _client.from('needs').insert(need.toJson()).select('id').single();
    return response['id'] as String;
  }

  Stream<List<Need>> watchMyNeeds(String userId) {
    return _client
        .from('needs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((data) => data.map((json) => Need.fromJson(json)).toList());
  }

  Future<List<Need>> getNearbyNeeds(
      double lat, double long, double radiusKm) async {
    final response = await _client
        .from('needs')
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false);

    final needs =
        (response as List).map((json) => Need.fromJson(json)).toList();

    return needs.where((need) {
      return DistanceCalculator.isWithinRadius(
        lat1: lat,
        lon1: long,
        lat2: need.latitude,
        lon2: need.longitude,
        radiusInKm: radiusKm,
      );
    }).toList();
  }

  Future<void> deleteNeed(String needId) async {
    await _client.from('needs').delete().eq('id', needId);
  }
}
