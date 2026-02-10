import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String? shopId;
  final String? businessId;
  final String name;
  final String description;
  final double price;
  final List<String> images;
  final int stockQuantity;
  final bool isAvailable;
  final DateTime createdAt;

  const Product({
    required this.id,
    this.shopId,
    this.businessId,
    required this.name,
    required this.description,
    required this.price,
    this.images = const [],
    this.stockQuantity = 0,
    this.isAvailable = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        shopId,
        businessId,
        name,
        description,
        price,
        images,
        stockQuantity,
        isAvailable,
        createdAt,
      ];
}
