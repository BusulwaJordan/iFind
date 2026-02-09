import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/constants/api_constants.dart';
import 'package:ifind/features/business/data/models/business_model.dart';
import 'package:ifind/features/business/domain/entities/business.dart';

class BusinessRemoteDataSource {
  final SupabaseClient supabaseClient;

  BusinessRemoteDataSource({required this.supabaseClient});

  /// Get nearby businesses using PostGIS
  Future<List<BusinessModel>> getNearbyBusinesses({
    required double latitude,
    required double longitude,
    required double radiusKm,
    BusinessCategory? category,
  }) async {
    try {
      // Using Supabase RPC call to a stored procedure for geospatial query
      // Note: This requires the 'nearby_businesses' function to be created in Supabase
      // created in schema.sql
      
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

      return response.map((json) => BusinessModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby businesses: $e');
    }
  }

  /// Create a new business
  Future<BusinessModel> createBusiness(Map<String, dynamic> businessData) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.businessesTable)
          .insert(businessData)
          .select()
          .single();

      return BusinessModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create business: $e');
    }
  }

  /// Get business by ID
  Future<BusinessModel> getBusinessById(String id) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.businessesTable)
          .select()
          .eq('id', id)
          .single();

      return BusinessModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch business: $e');
    }
  }

  /// Get businesses owned by user
  Future<List<BusinessModel>> getMyBusinesses(String ownerId) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.businessesTable)
          .select()
          .eq('owner_id', ownerId);

      return (response as List).map((json) => BusinessModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch my businesses: $e');
    }
  }

  /// Update business
  Future<BusinessModel> updateBusiness({
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

      return BusinessModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update business: $e');
    }
  }
}
