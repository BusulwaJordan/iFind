import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/business/domain/entities/business.dart';

abstract class BusinessRepository {
  /// Get businesses near a location
  Future<Either<Failure, List<Business>>> getNearbyBusinesses({
    required double latitude,
    required double longitude,
    required double radiusKm,
    BusinessCategory? category,
  });

  /// Get business by ID
  Future<Either<Failure, Business>> getBusinessById(String id);

  /// Get businesses owned by a user
  Future<Either<Failure, List<Business>>> getMyBusinesses(String ownerId);

  /// Create a new business
  Future<Either<Failure, Business>> createBusiness({
    required String ownerId,
    required String name,
    required String description,
    required BusinessCategory category,
    required double latitude,
    required double longitude,
    String? address,
    String? phone,
    String? website,
    String? email,
  });

  /// Update business details
  Future<Either<Failure, Business>> updateBusiness({
    required String businessId,
    String? name,
    String? description,
    String? phone,
    String? address,
  });
}
