import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/products/data/models/product_model.dart';
import 'package:ifind/features/products/domain/entities/product.dart';

class ProductRemoteDataSource {
  final SupabaseClient supabaseClient;

  ProductRemoteDataSource({required this.supabaseClient});

  /// `products.business_id` is the UUID primary key on `businesses`, but
  /// callers pass the custom text business id (e.g. "BIZ0122") used
  /// everywhere else in the app. Resolve the UUID before querying/writing.
  Future<String?> _resolveBusinessUuid(String businessId) async {
    final row = await supabaseClient
        .from('businesses')
        .select('id')
        .eq('business_id', businessId)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Future<List<Product>> getProductsByBusiness(String businessId) async {
    try {
      final resolvedId = await _resolveBusinessUuid(businessId) ?? businessId;
      final response = await supabaseClient
          .from('products')
          .select()
          .eq('business_id', resolvedId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProductModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<Product?> getProductById(String productId) async {
    try {
      final response = await supabaseClient
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();
      if (response == null) return null;
      return ProductModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      final businessId = productData['business_id'] as String?;
      if (businessId != null) {
        final resolvedId = await _resolveBusinessUuid(businessId);
        if (resolvedId != null) {
          productData = {...productData, 'business_id': resolvedId};
        }
      }

      final response = await supabaseClient
          .from('products')
          .insert(productData)
          .select()
          .single();

      return ProductModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<Product> updateProduct(
      String productId, Map<String, dynamic> updates) async {
    try {
      final response = await supabaseClient
          .from('products')
          .update(updates)
          .eq('id', productId)
          .select()
          .single();

      return ProductModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await supabaseClient.from('products').delete().eq('id', productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}
