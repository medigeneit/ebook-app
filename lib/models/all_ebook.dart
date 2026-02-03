import 'package:ebook_project/models/ebook.dart';

class AllEbook {
  final int softcopyId;
  final int productId;
  final String title;
  final String image;
  final String? summary;
  final Map<String, dynamic>? price;
  final dynamic packages;
  final bool allowCouponRenewal;
  final bool allowSubscription;
  final bool allowPremium;
  final String? features;
  final String? instructions;
  final Map<String, dynamic>? availability;

  AllEbook({
    required this.softcopyId,
    required this.productId,
    required this.title,
    required this.image,
    this.summary,
    this.price,
    this.packages,
    required this.allowCouponRenewal,
    required this.allowSubscription,
    required this.allowPremium,
    this.features,
    this.instructions,
    this.availability,
  });

  factory AllEbook.fromJson(Map<String, dynamic> json) {
    return AllEbook(
      softcopyId: _toInt(json['softcopy_id']) ?? 0,
      productId: _toInt(json['product_id']) ?? 0,
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      summary: json['summary']?.toString(),
      price: (json['price'] is Map)
          ? Map<String, dynamic>.from(json['price'])
          : null,
      packages: json['packages'],
      allowCouponRenewal: json['allow_coupon_renewal'] == true,
      allowSubscription: json['allow_subscription'] == true,
      allowPremium: json['allow_premium'] == true,
      features: json['features']?.toString(),
      instructions: json['instructions']?.toString(),
      availability: (json['availability'] is Map)
          ? Map<String, dynamic>.from(json['availability'])
          : null,
    );
  }

  Ebook toEbook() {
    return Ebook(
      id: softcopyId,
      subcriptionId: productId,
      image: image,
      name: title,
      status: 1,
      validity: availability?['starting']?.toString() ?? '',
      ending: availability?['ending']?.toString() ?? '',
      button: null,
      statusText: 'Active',
      isExpired: false,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }
}
