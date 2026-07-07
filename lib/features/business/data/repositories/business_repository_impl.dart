import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/core/services/storage_service.dart';
import 'package:ifind/features/business/data/datasources/business_remote_datasource.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/domain/repositories/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDataSource remoteDataSource;
  final StorageService storageService;

  BusinessRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

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
  Future<Either<Failure, List<Business>>> getFeaturedBusinesses() async {
    try {
      final businesses = await remoteDataSource.getNearbyBusinesses(
        latitude: 0.3476,
        longitude: 32.5825,
        radiusKm: 50,
      );
      return Right(businesses.take(3).toList());
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
    XFile? logoFile,
    XFile? coverFile,
  }) async {
    try {
      String? logoUrl;
      String? coverUrl;

      if (logoFile != null) {
        logoUrl = await storageService.uploadXFile(
          bucket: 'business_images',
          xFile: logoFile,
          path: 'logos/$ownerId',
        );
      }

      if (coverFile != null) {
        coverUrl = await storageService.uploadXFile(
          bucket: 'business_images',
          xFile: coverFile,
          path: 'covers/$ownerId',
        );
      }

      final businessData = {
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'category': category.storageValue,
        'latitude': latitude,
        'longitude': longitude,
        'location': 'POINT($longitude $latitude)', // PostGIS format
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (website != null) 'website': website,
        if (email != null) 'email': email,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (coverUrl != null) 'cover_image_url': coverUrl,
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
  Future<Either<Failure, List<Business>>> getMyBusinesses(
      String ownerId) async {
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
    BusinessCategory? category,
    String? phone,
    String? address,
    XFile? logoFile,
    XFile? coverFile,
  }) async {
    try {
      String? logoUrl;
      String? coverUrl;

      if (logoFile != null) {
        logoUrl = await storageService.uploadXFile(
          bucket: 'business_images',
          xFile: logoFile,
          path: 'logos/$businessId',
        );
      }

      if (coverFile != null) {
        coverUrl = await storageService.uploadXFile(
          bucket: 'business_images',
          xFile: coverFile,
          path: 'covers/$businessId',
        );
      }

      final updates = {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (category != null) 'category': category.storageValue,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (coverUrl != null) 'cover_image_url': coverUrl,
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

  @override
  Future<Either<Failure, void>> deleteBusiness(String id) async {
    try {
      await remoteDataSource.deleteBusiness(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Business?> watchBusiness(String id) {
    return remoteDataSource.watchBusiness(id);
  }

  @override
  Stream<List<Business>> watchMyBusinesses(String ownerId) {
    return remoteDataSource.watchMyBusinesses(ownerId);
  }

  @override
  Future<Either<Failure, void>> updateBusinessRating(String businessId) async {
    try {
      final response = await remoteDataSource.supabaseClient
          .from('reviews')
          .select('rating')
          .eq('business_id', businessId);

      final reviews = response as List;
      if (reviews.isEmpty) {
        await remoteDataSource.updateBusiness(
          businessId: businessId,
          updates: {
            'rating_average': 0.0,
            'rating_count': 0,
          },
        );
        return const Right(null);
      }

      final count = reviews.length;
      final sum = reviews.fold<int>(
          0, (prev, element) => prev + (element['rating'] as int));
      final average = sum / count;

      await remoteDataSource.updateBusiness(
        businessId: businessId,
        updates: {
          'rating_average': average,
          'rating_count': count,
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
