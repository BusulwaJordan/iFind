import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/core/services/storage_service.dart';
import 'package:ifind/features/products/data/datasources/product_remote_datasource.dart';
import 'package:ifind/features/products/domain/entities/product.dart';
import 'package:ifind/features/products/domain/repositories/product_repository.dart';
import 'package:ifind/features/portfolio/data/repositories/portfolio_repository.dart';
import 'package:ifind/features/portfolio/domain/entities/portfolio_item.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final StorageService storageService;
  final PortfolioRepository portfolioRepository;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
    required this.portfolioRepository,
  });

  @override
  Future<Either<Failure, List<Product>>> getProductsByBusiness(
      String businessId) async {
    try {
      final products = await remoteDataSource.getProductsByBusiness(businessId);
      return Right(products);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product?>> getProductById(String productId) async {
    try {
      final product = await remoteDataSource.getProductById(productId);
      return Right(product);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> createProduct({
    required String businessId,
    required String name,
    required String description,
    required double price,
    required int stockQuantity,
    List<XFile>? imageFiles,
  }) async {
    try {
      debugPrint(
          '[ProductRepository] Starting product creation for business: $businessId');
      debugPrint(
          '[ProductRepository] Product name: $name, price: $price, stock: $stockQuantity');

      final List<String> imageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        debugPrint(
            '[ProductRepository] Uploading ${imageFiles.length} images...');
        for (int i = 0; i < imageFiles.length; i++) {
          final file = imageFiles[i];
          debugPrint(
              '[ProductRepository] Uploading image ${i + 1}/${imageFiles.length}...');
          try {
            final url = await storageService.uploadXFile(
              bucket: 'product_images',
              xFile: file,
              path: 'products/$businessId',
            );
            imageUrls.add(url);
            debugPrint(
                '[ProductRepository] Image ${i + 1} uploaded successfully: $url');
          } catch (e) {
            debugPrint(
                '[ProductRepository] ERROR uploading image ${i + 1}: $e');
            return Left(ServerFailure('Failed to upload image ${i + 1}: $e'));
          }
        }
      }

      final productData = {
        'business_id': businessId,
        'name': name,
        'description': description,
        'price': price,
        'stock_quantity': stockQuantity,
        'images': imageUrls,
      };

      debugPrint('[ProductRepository] Inserting product data into database...');
      final product = await remoteDataSource.createProduct(productData);
      debugPrint(
          '[ProductRepository] Product created successfully: ${product.id}');

      // Surface the product's cover photo in the business's gallery. This is
      // a non-critical side effect — a failure here shouldn't fail the
      // product creation itself.
      if (imageUrls.isNotEmpty) {
        try {
          await portfolioRepository.addMediaUrlAsPortfolioItem(
            businessId: businessId,
            mediaUrl: imageUrls.first,
            mediaType: MediaType.image,
            caption: name,
            price: price,
            productId: product.id,
          );
        } catch (e) {
          debugPrint('[ProductRepository] Failed to add product to gallery: $e');
        }
      }

      return Right(product);
    } catch (e) {
      debugPrint('[ProductRepository] ERROR creating product: $e');
      debugPrint('[ProductRepository] Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        debugPrint(
            '[ProductRepository] Supabase error - Code: ${e.code}, Message: ${e.message}, Details: ${e.details}');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (price != null) updates['price'] = price;
      if (stockQuantity != null) updates['stock_quantity'] = stockQuantity;
      if (isAvailable != null) updates['is_available'] = isAvailable;

      if (existingImages != null || (newImageFiles != null && newImageFiles.isNotEmpty)) {
        final List<String> newUrls = [];
        if (newImageFiles != null) {
          for (final file in newImageFiles) {
            final url = await storageService.uploadXFile(
              bucket: 'product_images',
              xFile: file,
              path: 'products/updates/$productId',
            );
            newUrls.add(url);
          }
        }
        updates['images'] = [...?existingImages, ...newUrls];
      }

      final product = await remoteDataSource.updateProduct(productId, updates);

      // Keep the linked gallery post in sync. Non-critical — a failure here
      // shouldn't fail the product update itself.
      try {
        await portfolioRepository.syncProductPortfolioItem(
          businessId: businessId,
          productId: productId,
          coverImageUrl: product.images.isNotEmpty ? product.images.first : null,
          caption: product.name,
          price: product.price,
        );
      } catch (e) {
        debugPrint('[ProductRepository] Failed to sync product gallery post: $e');
      }

      return Right(product);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String productId) async {
    try {
      await remoteDataSource.deleteProduct(productId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
