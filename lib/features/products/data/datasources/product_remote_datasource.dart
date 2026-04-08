import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ifind/features/products/data/models/product_model.dart';
import 'package:ifind/features/products/domain/entities/product.dart';

class ProductRemoteDataSource {
  final SupabaseClient supabaseClient;

  ProductRemoteDataSource({required this.supabaseClient});

  Future<List<Product>> getProductsByBusiness(String businessId) async {
    try {
      final response = await supabaseClient
          .from('products')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProductModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
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
