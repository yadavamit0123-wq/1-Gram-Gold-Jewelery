import '../utils/constants.dart';

class CartItemModel {
  final int id;
  final int productId;
  final String name;
  final String? slug;
  final double price;
  final double? regularPrice;
  int quantity;
  final String? image;
  final int stockQuantity;
  final String? material;
  final String? goldType;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.name,
    this.slug,
    required this.price,
    this.regularPrice,
    required this.quantity,
    this.image,
    this.stockQuantity = 99,
    this.material,
    this.goldType,
  });

  double get subtotal => price * quantity;

  String get fullImageUrl => AppConstants.resolveImageUrl(image);

  bool get isOutOfStock => stockQuantity <= 0;
  bool get isQuantityExceedingStock => quantity > stockQuantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return CartItemModel(
      id: parseInt(json['id']),
      productId: parseInt(json['product_id']),
      name: json['name']?.toString() ?? json['product_name']?.toString() ?? 'Jewellery Item',
      slug: json['slug']?.toString() ?? json['product_slug']?.toString(),
      price: parseDouble(json['price'] ?? json['sale_price'] ?? json['unit_price']),
      regularPrice: json['regular_price'] != null ? parseDouble(json['regular_price']) : null,
      quantity: parseInt(json['quantity'] ?? 1),
      image: json['primary_image']?.toString() ?? json['image']?.toString(),
      stockQuantity: parseInt(json['stock_quantity'] ?? json['stock'] ?? 99),
      material: json['material']?.toString(),
      goldType: json['gold_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'slug': slug,
      'price': price,
      'regular_price': regularPrice,
      'quantity': quantity,
      'image': image,
      'stock_quantity': stockQuantity,
      'material': material,
      'gold_type': goldType,
    };
  }
}
