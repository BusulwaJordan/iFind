import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/constants/api_constants.dart';
import 'package:ifind/features/business/data/models/business_model.dart';
import 'package:ifind/features/business/domain/entities/business.dart';

class BusinessRemoteDataSource {
  final SupabaseClient supabaseClient;

  BusinessRemoteDataSource({required this.supabaseClient});

  /// Get nearby businesses using PostGIS
  Future<List<Business>> getNearbyBusinesses({
    required double latitude,
    required double longitude,
    required double radiusKm,
    BusinessCategory? category,
  }) async {
    try {
      final params = {
        'lat': latitude,
        'long': longitude,
        'radius_km': radiusKm,
        if (category != null) 'category_filter': category.name,
      };

      final List<dynamic> response = await supabaseClient.rpc(
        'get_nearby_businesses',
        params: params,
      );

      return response
          .map((json) => BusinessModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby businesses: $e');
    }
  }

  /// Create a new business
  Future<Business> createBusiness(Map<String, dynamic> businessData) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.businessesTable)
          .insert(businessData)
          .select()
          .single();

      return BusinessModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to create business: $e');
    }
  }

  /// Get business by ID
  Future<Business> getBusinessById(String id) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.businessesTable)
          .select()
          .eq('id', id)
          .single();

      return BusinessModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to fetch business: $e');
    }
  }

  /// Get businesses owned by user
  Future<List<Business>> getMyBusinesses(String ownerId) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.businessesTable)
          .select()
          .eq('owner_id', ownerId);

      return (response as List)
          .map((json) => BusinessModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch my businesses: $e');
    }
  }

  /// Update business
  Future<Business> updateBusiness({
    required String businessId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.businessesTable)
          .update(updates)
          .eq('id', businessId)
          .select()
          .single();

      return BusinessModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to update business: $e');
    }
  }

  /// Delete business
  Future<void> deleteBusiness(String id) async {
    try {
      await supabaseClient
          .from(ApiConstants.businessesTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete business: $e');
    }
  }

  /// Stream business by ID
  Stream<Business?> watchBusiness(String id) {
    return supabaseClient
        .from(ApiConstants.businessesTable)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) =>
            data.isEmpty ? null : BusinessModel.fromJson(data.first).toEntity());
  }

  /// Stream businesses owned by user
  Stream<List<Business>> watchMyBusinesses(String ownerId) {
    return supabaseClient
        .from(ApiConstants.businessesTable)
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .map((data) => data
            .map((json) => BusinessModel.fromJson(json).toEntity())
            .toList());
  }
}
