import 'package:iyadunni_shopmore/component.dart/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'productName': product.name, // top-level for easy admin reading
      'quantity': quantity,
      'price': product.price,
      'sellerIds': product.sellerIds ?? [], // ← KEY FIELD for seller filtering
      'shopName': product.shopName ?? '',
      'product': {
        'id': product.id,
        'name': product.name,
        'image': product.image,
        'price': product.price,
        'description': product.description,
        'category': product.category,
        'shortDescription': product.shortDescription,
        'sellerIds': product.sellerIds ?? [], // ← also inside product
        'shopName': product.shopName ?? '',
      },
    };
  }

  // Create from JSON from Firestore
  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'] as Map<String, dynamic>? ?? {};

    return CartItem(
      product: Product(
        id: productJson['id'] ?? '',
        name: productJson['name'] ?? '',
        image: productJson['image'] ?? '',
        price: (productJson['price'] as num?)?.toDouble() ?? 0.0,
        description: productJson['description'] ?? '',
        category: productJson['category'] ?? '',
        shortDescription: productJson['shortDescription'],
        sellerIds: productJson['sellerIds'], // ← read back sellerIds
        shopName: productJson['shopName'], // ← read back shopName
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
