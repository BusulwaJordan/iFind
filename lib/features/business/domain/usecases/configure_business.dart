import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/business/domain/entities/business.dart';
import 'package:ifind/features/business/domain/repositories/business_repository.dart';

class ConfigureBusiness {
  final BusinessRepository repository;

  ConfigureBusiness(this.repository);

  Future<Either<Failure, Business>> call({
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
  }) {
    return repository.createBusiness(
      ownerId: ownerId,
      name: name,
      description: description,
      category: category,
      latitude: latitude,
      longitude: longitude,
      address: address,
      phone: phone,
      website: website,
      email: email,
      logoFile: logoFile,
      coverFile: coverFile,
    );
  }
}
