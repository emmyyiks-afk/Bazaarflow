// Define your 3 different stores
enum FoodStore {
  iyadunni, // Iyadunni Foods (Main store)
  oau, // O.A.U Food Court (University area)
  buka, // Buka Republic (Local cuisine)
}

// Store information
class StoreInfo {
  final FoodStore store;
  final String name;
  final String description;
  final String image;
  final String location;
  final double rating;
  final int deliveryTime;

  StoreInfo({
    required this.store,
    required this.name,
    required this.description,
    required this.image,
    required this.location,
    required this.rating,
    required this.deliveryTime,
  });
}
