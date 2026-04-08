import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/exceptions.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:ifind/features/discovery/domain/repositories/discovery_repository.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final DiscoveryRemoteDataSource remoteDataSource;

  DiscoveryRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Business>>> getNearbyBusinesses({
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000.0,
  }) async {
    try {
      final models = await remoteDataSource.getNearbyBusinesses(
        latitude: latitude,
        longitude: longitude,
        radiusInMeters: radiusInMeters,
      );
      final businesses = models.map((model) => model.toEntity()).toList();
      return Right(businesses);
    } on DatabaseException catch (e) {
      return Left(ServerFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }
}
