import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/domain/repositories/business_repository.dart';

class GetNearbyBusinesses {
  final BusinessRepository repository;

  GetNearbyBusinesses(this.repository);

  Future<Either<Failure, List<Business>>> call({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    BusinessCategory? category,
  }) {
    return repository.getNearbyBusinesses(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      category: category,
    );
  }
}
