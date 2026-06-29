import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/constants/api_constants.dart';
import 'package:ifind/core/utils/distance_calculator.dart';
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
        if (category != null) 'category_filter': category.storageValue,
      };

      final response =
          await supabaseClient.rpc('get_nearby_businesses', params: params);

      return (response as List)
          .map((json) => BusinessModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      try {
        final fallback = await _getNearbyBusinessesFromTable(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
          category: category,
        );
        if (fallback.isNotEmpty) {
          return fallback;
        }
      } catch (_) {}

      throw Exception('Failed to fetch nearby businesses: $e');
    }
  }

  Future<List<Business>> _getNearbyBusinessesFromTable({
    required double latitude,
    required double longitude,
    required double radiusKm,
    BusinessCategory? category,
  }) async {
    dynamic query = supabaseClient.from(ApiConstants.businessesTable).select();
    if (category != null) {
      query = query.eq('category', category.storageValue);
    }

    final response = await query;
    final businesses = (response as List)
        .map((json) {
          final data = Map<String, dynamic>.from(json as Map);
          final business = BusinessModel.fromJson(data).toEntity();
          final distance = DistanceCalculator.calculateDistance(
            lat1: latitude,
            lon1: longitude,
            lat2: business.latitude,
            lon2: business.longitude,
          );
          return business.copyWith(distance: distance);
        })
        .where((business) => business.distance != null)
        .where((business) => business.distance! <= radiusKm)
        .toList()
      ..sort((a, b) {
        final distanceCompare = a.distance!.compareTo(b.distance!);
        if (distanceCompare != 0) return distanceCompare;
        return b.rating.compareTo(a.rating);
      });

    return businesses;
  }

  /// Create a new business
  Future<Business> createBusiness(Map<String, dynamic> businessData) async {
    try {
      // Get all existing business IDs to count them
      final allBusinesses = await supabaseClient
          .from(ApiConstants.businessesTable)
          .select('business_id');
      
      final count = (allBusinesses as List).length;
      final nextId = 'BIZ${(count + 1).toString().padLeft(4, '0')}';
      businessData['business_id'] = nextId;

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
      final response = await _selectBusinessById(id);

      return BusinessModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to fetch business: $e');
    }
  }

  Future<Map<String, dynamic>> _selectBusinessById(String id) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.businessesTable)
          .select()
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(response);
    } catch (_) {
      final response = await supabaseClient
          .from(ApiConstants.businessesTable)
          .select()
          .eq('business_id', id)
          .single();
      return Map<String, dynamic>.from(response);
    }
  }

  /// Get businesses owned by user
  Future<List<Business>> getMyBusinesses(String ownerId) async {
    try {
      final response = await _selectBusinessesOwnedBy(ownerId);

      return response
          .map((json) => BusinessModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch my businesses: $e');
    }
  }

  Future<List<dynamic>> _selectBusinessesOwnedBy(String ownerId) async {
    try {
      return await supabaseClient
          .from(ApiConstants.businessesTable)
          .select()
          .eq('owner_id', ownerId);
    } catch (_) {
      return await supabaseClient
          .from(ApiConstants.businessesTable)
          .select()
          .eq('user_id', ownerId);
    }
  }

  /// Update business
  Future<Business> updateBusiness({
    required String businessId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _updateBusinessById(
        businessId: businessId,
        updates: updates,
      );

      return BusinessModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to update business: $e');
    }
  }

  Future<Map<String, dynamic>> _updateBusinessById({
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
      return Map<String, dynamic>.from(response);
    } catch (_) {
      final response = await supabaseClient
          .from(ApiConstants.businessesTable)
          .update(updates)
          .eq('business_id', businessId)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    }
  }

  /// Delete business
  Future<void> deleteBusiness(String id) async {
    try {
      try {
        await supabaseClient
            .from(ApiConstants.businessesTable)
            .delete()
            .eq('id', id);
      } catch (_) {
        await supabaseClient
            .from(ApiConstants.businessesTable)
            .delete()
            .eq('business_id', id);
      }
    } catch (e) {
      throw Exception('Failed to delete business: $e');
    }
  }

  /// Stream business by ID — falls back to a one-shot fetch when realtime fails
  Stream<Business?> watchBusiness(String id) async* {
    // Emit the latest REST snapshot immediately so the screen is never blank.
    try {
      final snap = await _selectBusinessById(id);
      yield BusinessModel.fromJson(snap).toEntity();
    } catch (_) {
      yield null;
    }

    // Then layer on a live subscription for real-time updates.
    // Swallow any realtime errors so the screen keeps showing the snapshot.
    await for (final row in supabaseClient
        .from(ApiConstants.businessesTable)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .handleError((_) {})
        .asyncMap((data) async {
          if (data.isEmpty) return null;
          try {
            return BusinessModel.fromJson(data.first).toEntity();
          } catch (_) {
            return null;
          }
        })) {
      if (row != null) yield row;
    }
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