class Product {
  final String id;
  final String name;
  final String image;
  final List<String>? extraImages; // ← optional List, not required String
  final double price;
  final String description;
  final String category;
  final String? shortDescription;
  int quantity;
  final List<String>? sellerIds; // ← ADD THIS
  final String? shopName;

  Product({
    required this.id,
    required this.name,
    required this.image,
    this.extraImages, // ← optional, no 'required'
    required this.price,
    required this.description,
    required this.category,
    this.shortDescription,
    this.quantity = 1,
    this.sellerIds, // ← ADD THIS
    this.shopName, // ← ADD THIS
  });
}
