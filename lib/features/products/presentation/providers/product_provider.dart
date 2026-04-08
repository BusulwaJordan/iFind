import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/features/products/data/datasources/product_remote_datasource.dart';
import 'package:ifind/features/products/data/repositories/product_repository_impl.dart';
import 'package:ifind/features/products/domain/entities/product.dart';
import 'package:ifind/features/products/domain/repositories/product_repository.dart';
import 'package:ifind/features/business/presentation/providers/business_provider.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';

// Product Data Source Provider
final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  return ProductRemoteDataSource(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

// Product Repository Provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    remoteDataSource: ref.watch(productRemoteDataSourceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

// Products for a specific business
final businessProductsProvider = FutureProvider.family<List<Product>, String>((ref, businessId) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getProductsByBusiness(businessId);
  return result.fold(
    (failure) => [],
    (products) => products,
  );
});
