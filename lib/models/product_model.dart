import '../utils/constants.dart';

class ProductModel {
  final int id;
  final int categoryId;
  final int? subcategoryId;
  final String name;
  final String slug;
  final String sku;
  final String? shortDescription;
  final String? longDescription;
  final double regularPrice;
  final double? salePrice;
  final double? weight;
  final String? dimensions;
  final String? material;
  final int stockQuantity;
  final bool isFeatured;
  final bool isBestseller;
  final bool isNewArrival;
  final String status;
  final String? goldType;
  final double? goldWeight;
  final double? makingCharges;
  final double? gstPercentage;
  final String? size;
  final String? color;
  final String? primaryImage;
  final List<String> images;
  final String? categoryName;
  final String? subcategoryName;

  ProductModel({
    required this.id,
    required this.categoryId,
    this.subcategoryId,
    required this.name,
    required this.slug,
    required this.sku,
    this.shortDescription,
    this.longDescription,
    required this.regularPrice,
    this.salePrice,
    this.weight,
    this.dimensions,
    this.material,
    required this.stockQuantity,
    this.isFeatured = false,
    this.isBestseller = false,
    this.isNewArrival = false,
    this.status = 'active',
    this.goldType,
    this.goldWeight,
    this.makingCharges,
    this.gstPercentage,
    this.size,
    this.color,
    this.primaryImage,
    this.images = const [],
    this.categoryName,
    this.subcategoryName,
  });

  // Effective selling price
  double get price => (salePrice != null && salePrice! > 0 && salePrice! < regularPrice)
      ? salePrice!
      : regularPrice;

  bool get hasDiscount => salePrice != null && salePrice! > 0 && salePrice! < regularPrice;

  int get discountPercent {
    if (!hasDiscount || regularPrice <= 0) return 0;
    return (((regularPrice - salePrice!) / regularPrice) * 100).round();
  }

  double get savings => hasDiscount ? (regularPrice - salePrice!) : 0.0;

  bool get isInStock => stockQuantity > 0;

  bool get isGoldJewellery =>
      material?.toLowerCase().contains('gold') == true ||
      (categoryName != null && categoryName!.toLowerCase().contains('gold')) ||
      (goldType != null && goldType!.isNotEmpty);

  bool get hasBreakdown =>
      (goldWeight != null && goldWeight! > 0) ||
      (makingCharges != null && makingCharges! > 0) ||
      (gstPercentage != null && gstPercentage! > 0);

  String get fullImageUrl => AppConstants.resolveImageUrl(primaryImage);

  List<String> get allImageUrls {
    final list = <String>[];
    if (primaryImage != null && primaryImage!.isNotEmpty) {
      list.add(AppConstants.resolveImageUrl(primaryImage));
    }
    for (final img in images) {
      final resolved = AppConstants.resolveImageUrl(img);
      if (resolved.isNotEmpty && !list.contains(resolved)) {
        list.add(resolved);
      }
    }
    return list.isEmpty ? [AppConstants.resolveImageUrl(null)] : list;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse images array
    final imageList = <String>[];
    if (json['images'] is List) {
      for (final img in json['images']) {
        if (img is String) {
          imageList.add(img);
        } else if (img is Map<String, dynamic> && img['image_url'] != null) {
          imageList.add(img['image_url'].toString());
        }
      }
    }

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

    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      final str = val.toString().toLowerCase();
      return str == '1' || str == 'true' || str == 'yes';
    }

    return ProductModel(
      id: parseInt(json['id']),
      categoryId: parseInt(json['category_id']),
      subcategoryId: json['subcategory_id'] != null ? parseInt(json['subcategory_id']) : null,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      shortDescription: json['short_description']?.toString(),
      longDescription: json['long_description']?.toString() ?? json['description']?.toString(),
      regularPrice: parseDouble(json['regular_price'] ?? json['mrp'] ?? json['price']),
      salePrice: json['sale_price'] != null
          ? parseDouble(json['sale_price'])
          : (json['price'] != null && json['mrp'] != null && parseDouble(json['price']) < parseDouble(json['mrp'])
              ? parseDouble(json['price'])
              : null),
      weight: json['weight'] != null ? parseDouble(json['weight']) : null,
      dimensions: json['dimensions']?.toString() ?? json['size']?.toString(),
      material: json['material']?.toString(),
      stockQuantity: parseInt(json['stock_quantity']),
      isFeatured: parseBool(json['is_featured']),
      isBestseller: parseBool(json['is_bestseller'] ?? json['is_best_seller']),
      isNewArrival: parseBool(json['is_new_arrival']),
      status: json['status']?.toString() ?? 'active',
      goldType: json['gold_type']?.toString(),
      goldWeight: json['gold_weight'] != null ? parseDouble(json['gold_weight']) : null,
      makingCharges: json['making_charges'] != null
          ? parseDouble(json['making_charges'])
          : (json['making_charge'] != null ? parseDouble(json['making_charge']) : null),
      gstPercentage: json['gst_percentage'] != null
          ? parseDouble(json['gst_percentage'])
          : (json['gst_percent'] != null ? parseDouble(json['gst_percent']) : null),
      size: json['size']?.toString(),
      color: json['color']?.toString() ?? json['color_finish']?.toString(),
      primaryImage: json['primary_image']?.toString() ?? json['image']?.toString(),
      images: imageList,
      categoryName: json['category_name']?.toString(),
      subcategoryName: json['subcategory_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'name': name,
      'slug': slug,
      'sku': sku,
      'short_description': shortDescription,
      'long_description': longDescription,
      'regular_price': regularPrice,
      'sale_price': salePrice,
      'weight': weight,
      'dimensions': dimensions,
      'material': material,
      'stock_quantity': stockQuantity,
      'is_featured': isFeatured ? 1 : 0,
      'is_bestseller': isBestseller ? 1 : 0,
      'is_new_arrival': isNewArrival ? 1 : 0,
      'status': status,
      'gold_type': goldType,
      'gold_weight': goldWeight,
      'making_charges': makingCharges,
      'gst_percentage': gstPercentage,
      'size': size,
      'color': color,
      'primary_image': primaryImage,
      'images': images,
      'category_name': categoryName,
      'subcategory_name': subcategoryName,
    };
  }
}
