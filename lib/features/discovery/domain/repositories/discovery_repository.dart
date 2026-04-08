import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/business/domain/entities/business.dart';

abstract class DiscoveryRepository {
  Future<Either<Failure, List<Business>>> getNearbyBusinesses({
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000.0,
  });
}
