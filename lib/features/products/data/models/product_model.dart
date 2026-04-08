import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ifind/features/products/domain/entities/product.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    required String id,
    @JsonKey(name: 'shop_id') String? shopId,
    @JsonKey(name: 'business_id') String? businessId,
    required String name,
    String? description,
    required double price,
    @Default([]) List<String> images,
    @JsonKey(name: 'stock_quantity') @Default(0) int stockQuantity,
    @JsonKey(name: 'is_available') @Default(true) bool isAvailable,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  const ProductModel._();

  Product toEntity() => Product(
        id: id,
        shopId: shopId,
        businessId: businessId,
        name: name,
        description: description,
        price: price,
        images: images,
        stockQuantity: stockQuantity,
        isAvailable: isAvailable,
        createdAt: createdAt,
      );

  factory ProductModel.fromEntity(Product product) => ProductModel(
        id: product.id,
        shopId: product.shopId,
        businessId: product.businessId,
        name: product.name,
        description: product.description,
        price: product.price,
        images: product.images,
        stockQuantity: product.stockQuantity,
        isAvailable: product.isAvailable,
        createdAt: product.createdAt,
      );
}
