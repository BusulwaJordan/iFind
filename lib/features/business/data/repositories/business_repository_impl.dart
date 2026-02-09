import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/business/data/datasources/business_remote_datasource.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/domain/repositories/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDataSource remoteDataSource;

  BusinessRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Business>>> getNearbyBusinesses({
    required double latitude,
    required double longitude,
    required double radiusKm,
    BusinessCategory? category,
  }) async {
    try {
      final businesses = await remoteDataSource.getNearbyBusinesses(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        category: category,
      );
      return Right(businesses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final businessData = {
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'category': category.name,
        'latitude': latitude,
        'longitude': longitude,
        'location': 'POINT($longitude $latitude)', // PostGIS format
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (website != null) 'website': website,
        if (email != null) 'email': email,
      };

      final business = await remoteDataSource.createBusiness(businessData);
      return Right(business);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Business>> getBusinessById(String id) async {
    try {
      final business = await remoteDataSource.getBusinessById(id);
      return Right(business);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Business>>> getMyBusinesses(String ownerId) async {
    try {
      final businesses = await remoteDataSource.getMyBusinesses(ownerId);
      return Right(businesses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Business>> updateBusiness({
    required String businessId,
    String? name,
    String? description,
    String? phone,
    String? address,
  }) async {
    try {
      final updates = {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      };

      final business = await remoteDataSource.updateBusiness(
        businessId: businessId,
        updates: updates,
      );
      return Right(business);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
