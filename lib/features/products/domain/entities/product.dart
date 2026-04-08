import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    String? shopId,
    String? businessId,
    required String name,
    String? description,
    required double price,
    @Default([]) List<String> images,
    @Default(0) int stockQuantity,
    @Default(true) bool isAvailable,
    required DateTime createdAt,
  }) = _Product;
}
