import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/errors/exceptions.dart';
import 'package:ifind/features/business/data/models/business_model.dart';

abstract class DiscoveryRemoteDataSource {
  Future<List<BusinessModel>> getNearbyBusinesses({
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000.0,
  });
}

class DiscoveryRemoteDataSourceImpl implements DiscoveryRemoteDataSource {
  final SupabaseClient supabase;

  DiscoveryRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<BusinessModel>> getNearbyBusinesses({
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000.0,
  }) async {
    try {
      final response = await supabase.rpc('get_nearby_businesses', params: {
        'user_lat': latitude,
        'user_lon': longitude,
        'radius_meters': radiusInMeters,
      });

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => BusinessModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message);
    } catch (e) {
      throw ServerException('Failed to find nearby businesses: $e');
    }
  }
}
