import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/products/domain/entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProductsByBusiness(String businessId);
  Future<Either<Failure, Product?>> getProductById(String productId);
  Future<Either<Failure, Product>> createProduct({
    required String businessId,
    required String name,
    required String description,
    required double price,
    required int stockQuantity,
    List<XFile>? imageFiles,
  });
  Future<Either<Failure, Product>> updateProduct({
    required String productId,
    required String businessId,
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    bool? isAvailable,
    List<String>? existingImages,
    List<XFile>? newImageFiles,
  });
  Future<Either<Failure, void>> deleteProduct(String productId);
}
