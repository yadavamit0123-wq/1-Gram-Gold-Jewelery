class SubcategoryModel {
  final int id;
  final int categoryId;
  final String name;
  final String slug;
  final String? description;
  final String? image;

  SubcategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    this.description,
    this.image,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'slug': slug,
      'description': description,
      'image': image,
    };
  }
}

class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? image;
  final String? bannerUrl;
  final List<SubcategoryModel> subcategories;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.image,
    this.bannerUrl,
    this.subcategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final subcategoriesList = <SubcategoryModel>[];
    if (json['subcategories'] is List) {
      for (final sub in json['subcategories']) {
        if (sub is Map<String, dynamic>) {
          subcategoriesList.add(SubcategoryModel.fromJson(sub));
        }
      }
    }

    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      bannerUrl: json['banner_url']?.toString(),
      subcategories: subcategoriesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'image': image,
      'banner_url': bannerUrl,
      'subcategories': subcategories.map((s) => s.toJson()).toList(),
    };
  }
}
