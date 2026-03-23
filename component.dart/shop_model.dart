// models/shop_model.dart
import 'package:iyadunni_shopmore/component.dart/product.dart';

class Shop {
  final String id;
  final String name;
  final String ownerName;
  final String logoImage;
  final String coverImage;
  final String description;
  final double rating;
  final int reviewCount;
  final int deliveryTime;
  final double deliveryFee;
  final double minimumOrder;
  final bool isOpen;
  final bool isVerified;
  final String address;
  final String phone;
  final List<String> categories;
  final List<Product> products;

  Shop({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.logoImage,
    required this.coverImage,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.minimumOrder,
    required this.isOpen,
    required this.isVerified,
    required this.address,
    required this.phone,
    required this.categories,
    required this.products,
  });
}
