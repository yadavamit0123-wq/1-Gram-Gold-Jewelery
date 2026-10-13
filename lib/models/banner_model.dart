import '../utils/constants.dart';

class BannerModel {
  final int id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? linkUrl;
  final String bannerType;
  final int displayOrder;

  BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.linkUrl,
    this.bannerType = 'hero',
    this.displayOrder = 0,
  });

  String get fullImageUrl => AppConstants.resolveImageUrl(imageUrl);

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString() ?? '',
      linkUrl: json['link_url']?.toString(),
      bannerType: json['banner_type']?.toString() ?? 'hero',
      displayOrder: json['display_order'] is int
          ? json['display_order']
          : int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'banner_type': bannerType,
      'display_order': displayOrder,
    };
  }
}
