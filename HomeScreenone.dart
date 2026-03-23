import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iyadunni_shopmore/check_out_page.dart';
import 'package:iyadunni_shopmore/component.dart/cart_items.dart';
import 'package:iyadunni_shopmore/component.dart/mydrawer.dart';
import 'package:iyadunni_shopmore/component.dart/myfood_Item.dart';
import 'package:iyadunni_shopmore/component.dart/product.dart';
import 'package:iyadunni_shopmore/component.dart/check_out_model.dart';
import 'package:iyadunni_shopmore/component.dart/shop_model.dart';
import 'package:iyadunni_shopmore/kitchen_screen.dart';
import 'package:iyadunni_shopmore/navigate_to_order_history.dart';
import 'package:iyadunni_shopmore/service/firestore_service.dart';
import 'package:iyadunni_shopmore/clothing_detail_screen.dart'; // ← NEW
import 'package:provider/provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════════════
class _D {
  static const blue900 = Color(0xFF0D3380);
  static const blue800 = Color(0xFF1240A8);
  static const blue700 = Color(0xFF1A56DB);
  static const blue600 = Color(0xFF2563EB);
  static const blue500 = Color(0xFF3B82F6);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFFFBEB);
  static const green = Color(0xFF059669);
  static const green50 = Color(0xFFECFDF5);
  static const surface = Color(0xFFF0F5FF);
  static const card = Colors.white;
  static const border = Color(0xFFDDE5F7);
  static const ink = Color(0xFF0F1E40);
  static const inkMid = Color(0xFF4B5E82);
  static const inkLight = Color(0xFF8FA2C4);
  static const blue300 = Color(0xFF93C5FD);
  static const gradTop = Color(0xFF0D3380);
  static const gradMid = Color(0xFF1A56DB);
  static const gradLow = Color(0xFF3B82F6);
}

// ═══════════════════════════════════════════════════════════════════════════
// HOME SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class HomeScreenOne extends StatefulWidget {
  const HomeScreenOne({super.key});

  @override
  State<HomeScreenOne> createState() => _HomeScreenOneState();
}

class _HomeScreenOneState extends State<HomeScreenOne>
    with TickerProviderStateMixin {
  List<Orders> _orders = [];
  final FirestoreService _firestoreService = FirestoreService();
  Stream<List<Orders>>? _ordersStream;
  StreamSubscription<List<Orders>>? _ordersSubscription;
  bool _isFirestoreConnected = false;
  String _firestoreStatus = 'Initializing...';
  bool _isLoading = true;
  String? _firestoreError;

  User? _currentUser;
  bool _isUserSignedIn = false;

  int _selectedTabIndex = 0;
  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Food', 'icon': Icons.restaurant_rounded},
    {'label': 'Gadgets', 'icon': Icons.devices_rounded},
    {'label': 'Drinks', 'icon': Icons.local_drink_rounded},
    {'label': 'Other', 'icon': Icons.grid_view_rounded},
  ];

  List<CartItem> _cartItems = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  final FocusNode _searchFocus = FocusNode();

  late AnimationController _headerAnim;
  late AnimationController _tabAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  int _bottomNavIndex = 0;

  // ═══════════════════════════════════════════════════════════════════════
  // PRODUCT DATA
  // ═══════════════════════════════════════════════════════════════════════
  final List<Shop> _shops = [
    Shop(
      id: 'shop1',
      name: "Dibbie's Kitchen",
      ownerName: 'Dibbie Kitchen',
      logoImage: 'assets/Dibbie\'s Kitchen.jpg',
      coverImage: 'assets/Dibbie\'s Kitchen.jpg',
      description:
          'Home of the famous Jumbo Akara! Authentic Nigerian cuisine with a modern twist.',
      rating: 0.0,
      reviewCount: 30,
      deliveryTime: 30,
      deliveryFee: 500,
      minimumOrder: 1000,
      isOpen: true,
      isVerified: true,
      address: '12, Akara Street, Ikeja, Lagos',
      phone: '+234 9151485641',
      categories: ['African', 'Breakfast', 'Swallow'],
      products: [
        Product(
            id: '1',
            name: 'Iyadunni Akara (Jumbo Special)',
            image: 'assets/image-5.jpg',
            price: 500,
            description: "Whether you're craving a hearty breakfast...",
            category: 'Food',
            shortDescription: 'Jumbo long akara with crayfish',
            quantity: 1,
            sellerIds: ['BmvRW6Pp5DWkeF72eCGxDcHeXXB3'],
            shopName: "Dibbie's Kitchen"),
        Product(
            id: '2',
            name: 'Pounded Yam and Vegetable soup',
            image: 'assets/images (2).jpeg',
            price: 500,
            description: "Dive into the perfect combo!...",
            category: 'Food',
            shortDescription: 'Smooth pounded yam with vegetable soup',
            quantity: 1,
            sellerIds: ['BmvRW6Pp5DWkeF72eCGxDcHeXXB3'],
            shopName: "Dibbie's Kitchen"),
        Product(
            id: '3',
            name: 'Efo Riro with Pounded Yam',
            image: 'assets/Efo Riro nd pounded yam.jpg',
            price: 500,
            description: "Experience the rich flavors...",
            category: 'Food',
            shortDescription: 'Savory spinach stew with pounded yam',
            quantity: 1,
            sellerIds: ['BmvRW6Pp5DWkeF72eCGxDcHeXXB3'],
            shopName: "Dibbie's Kitchen"),
        Product(
            id: '4',
            name: 'Fried Rice',
            image: 'assets/Fried Rice.png',
            price: 400,
            description: "Irresistible smoky fried rice...",
            category: 'Food',
            shortDescription: 'Crispy fried rice',
            quantity: 1,
            sellerIds: ['BmvRW6Pp5DWkeF72eCGxDcHeXXB3'],
            shopName: "Dibbie's Kitchen"),
        Product(
            id: '5',
            name: 'Jollof Rice',
            image: 'assets/Jollof Rice.jpg',
            price: 400,
            description: "Rich, aromatic jollof rice...",
            category: 'Food',
            shortDescription: 'Spicy jollof rice',
            quantity: 1,
            sellerIds: ['BmvRW6Pp5DWkeF72eCGxDcHeXXB3'],
            shopName: "Dibbie's Kitchen"),
        Product(
            id: '6',
            name: 'Amala and Ewedu Soup',
            image: 'assets/Emala_Ewedu soup.jpg',
            price: 400,
            description: "Savor the unique taste...",
            category: 'Food',
            shortDescription: 'Earthy amala with ewedu',
            quantity: 1,
            sellerIds: ['BmvRW6Pp5DWkeF72eCGxDcHeXXB3'],
            shopName: "Dibbie's Kitchen"),
        Product(
            id: '7',
            name: 'Amala and Egusi Soup',
            image: 'assets/Amala_Egusi soup.jpg',
            price: 400,
            description: "Our Amala is soft and stretchy...",
            category: 'Food',
            shortDescription: 'Soft amala with egusi',
            quantity: 1,
            sellerIds: ['BmvRW6Pp5DWkeF72eCGxDcHeXXB3'],
            shopName: "Dibbie's Kitchen"),
        Product(
            id: '8',
            name: 'Amala and Efo Riro Soup',
            image: 'assets/Amala_Efo2.jpg',
            price: 400,
            description: "Our Amala is soft and stretchy...",
            category: 'Food',
            shortDescription: 'Soft amala with efo riro',
            quantity: 1,
            sellerIds: ['BmvRW6Pp5DWkeF72eCGxDcHeXXB3'],
            shopName: "Dibbie's Kitchen"),
        Product(
            id: '9',
            name: 'Chicken and chips (maxi)',
            image: 'assets/Chicken_chips.webp',
            price: 4200,
            description: "Indulge in our crispy, golden fried chicken...",
            category: 'Food',
            quantity: 1,
            sellerIds: ['BmvRW6Pp5DWkeF72eCGxDcHeXXB3'],
            shopName: "Dibbie's Kitchen"),
        Product(
            id: '10',
            name: 'Chicken and Chips',
            image: 'assets/chicken_chips_midi.jpg',
            price: 3200,
            description:
                "Crispy fried chicken with perfectly seasoned chips...",
            category: 'Food',
            quantity: 1,
            sellerIds: ['BmvRW6Pp5DWkeF72eCGxDcHeXXB3'],
            shopName: "Dibbie's Kitchen"),
        Product(
            id: '11',
            name: 'Chicken Shawarma',
            image: 'assets/chicken_chips_midi.jpg',
            price: 2400,
            description: "Spicy, juicy shawarma dripping with garlic sauce...",
            category: 'Food',
            quantity: 1,
            sellerIds: ['BmvRW6Pp5DWkeF72eCGxDcHeXXB3'],
            shopName: "Dibbie's Kitchen"),
        Product(
            id: '12',
            name: 'Meats',
            image: 'assets/chicken_meat2.webp',
            price: 500,
            description: "Juicy, tender, protein-rich...",
            category: 'Food',
            quantity: 1,
            sellerIds: ['BmvRW6Pp5DWkeF72eCGxDcHeXXB3'],
            shopName: "Dibbie's Kitchen"),
      ],
    ),
    Shop(
      id: 'shop2',
      name: 'OAU Kitchen Court',
      ownerName: 'OAU Students',
      logoImage: 'assets/O.A.U. kitchen Court.jpg',
      coverImage: 'assets/O.A.U. kitchen Court.jpg',
      description:
          'Student-friendly prices, campus favorite! Quality food for the academic community.',
      rating: 0.0,
      reviewCount: 20,
      deliveryTime: 45,
      deliveryFee: 300,
      minimumOrder: 500,
      isOpen: true,
      isVerified: true,
      address: 'Inside OAU Campus, Ile-Ife',
      phone: '+234 9151485641',
      categories: ['Student Meals', 'Rice', 'Fast Food'],
      products: [
        Product(
            id: '13',
            name: 'O.A.U Fried Rice',
            image: 'assets/Fried Rice.png',
            price: 500,
            description: "Student special: Smoky fried rice...",
            category: 'Food',
            shortDescription: 'Popular student fried rice',
            quantity: 1),
        Product(
            id: '14',
            name: 'O.A.U Jollof Rice',
            image: 'assets/Jollof Rice.jpg',
            price: 500,
            description: "Party jollof rice just like event servings!",
            category: 'Food',
            shortDescription: 'Event-style jollof rice',
            quantity: 1),
        Product(
            id: '15',
            name: 'O.A.U. White Rice',
            image: 'assets/eatry_rice.jpg',
            price: 500,
            description: "Fluffy, fragrant, and perfectly cooked...",
            category: 'Food',
            quantity: 1),
        Product(
            id: '16',
            name: 'O.A.U. Meats',
            image: 'assets/chicken_meat2.webp',
            price: 600,
            description: "Juicy, tender, protein-rich...",
            category: 'Food',
            quantity: 1),
        Product(
            id: '17',
            name: 'O.A.U. Egg',
            image: 'assets/cooked_egg.jpeg',
            price: 500,
            description: "Premium free-range eggs...",
            category: 'Food',
            quantity: 1),
        Product(
            id: '18',
            name: 'O.A.U. Fish',
            image: 'assets/image_for_fishbig.jpg',
            price: 600,
            description: "Spicy stuffed catfish in rich red stew...",
            category: 'Food',
            quantity: 1),
        Product(
            id: '19',
            name: 'O.A.U. Amala and Vegetable soup',
            image: 'assets/Amala_Egusi soup.jpg',
            price: 500,
            description: "Our Amala is soft and stretchy...",
            category: 'Food',
            quantity: 1),
        Product(
            id: '20',
            name: 'O.A.U. Amala and Efo Riro Soup',
            image: 'assets/Amala_Efo2.jpg',
            price: 500,
            description: "Our Amala is soft and stretchy...",
            category: 'Food',
            shortDescription: 'Soft amala with efo riro',
            quantity: 1),
        Product(
            id: '21',
            name: 'O.A.U. Eba and Vegetable Soup',
            image: 'assets/eba and vegetable.jpg',
            price: 500,
            description: "Our Eba is soft and stretchy...",
            category: 'Food',
            shortDescription: 'Soft eba with vegetable soup',
            quantity: 1),
        Product(
            id: '22',
            name: 'O.A.U. Eba and Ewedu Soup',
            image: 'assets/eba_ewedu.jpg',
            price: 500,
            description: "Our Eba is soft and stretchy...",
            category: 'Food',
            shortDescription: 'Soft eba with ewedu',
            quantity: 1),
        Product(
            id: '23',
            name: 'O.A.U. Pounded Yam and Veg soup',
            image: 'assets/images (2).jpeg',
            price: 500,
            description: "Dive into the perfect combo!...",
            category: 'Food',
            shortDescription: 'Smooth pounded yam with vegetable soup',
            quantity: 1),
        Product(
            id: '24',
            name: 'O.A.U. Efo Riro with Pounded Yam',
            image: 'assets/Efo Riro nd pounded yam.jpg',
            price: 700,
            description: "Experience the rich flavors...",
            category: 'Food',
            shortDescription: 'Savory spinach stew with pounded yam',
            quantity: 1),
        Product(
            id: '25',
            name: 'O.A.U. Ponma meat',
            image: 'assets/ponma_meat.jpg',
            price: 500,
            description: "Steaming ponmo in vibrant red stew...",
            category: 'Food',
            quantity: 1),
      ],
    ),
  ];

  final List<Product> _gadgetProducts = [
    Product(
        id: 'g1',
        name: 'Wireless Bluetooth Earbuds',
        image: 'assets/airbud.png',
        price: 15000,
        description:
            'High-quality wireless earbuds with noise cancellation, 30hr battery life.',
        category: 'Gadgets',
        shortDescription: 'Premium wireless earbuds with ANC',
        quantity: 1),
    Product(
        id: 'g2',
        name: 'Smart Watch Series 5',
        image: 'assets/smart_watch.2.jpg',
        price: 35000,
        description:
            'Track fitness, receive notifications, monitor heart rate.',
        category: 'Gadgets',
        shortDescription: 'Advanced fitness tracking smart watch',
        quantity: 1),
    Product(
        id: 'g3',
        name: 'Portable Power Bank 20000mAh',
        image: 'assets/oraimo_new_20000.webp',
        price: 20000,
        description:
            'Fast charging power bank with multiple ports, slim design.',
        category: 'Gadgets',
        shortDescription: 'Massive 20000mAh capacity, charge 4–8 times',
        quantity: 1),
    Product(
        id: 'g4',
        name: 'USB-C Hub 7-in-1',
        image: 'assets/adaptor_advance.webp',
        price: 12000,
        description:
            'Expand your laptop connectivity with HDMI, USB, SD slots.',
        category: 'Gadgets',
        shortDescription: 'Multi-port adapter for laptops',
        quantity: 1),
    Product(
        id: 'g5',
        name: 'Oraimo Powerbank 40000mAh',
        image: 'assets/oraimo_new_40000.jpg',
        price: 50000,
        description:
            'High capacity power bank with fast charging, multiple ports.',
        category: 'Gadgets',
        shortDescription: 'Massive 40000mAh, stay connected all day',
        quantity: 1),
    Product(
        id: 'g6',
        name: 'Hand Fan',
        image: 'assets/hand_fan.avif',
        price: 15000,
        description: 'Rechargeable slim hand fan, perfect for Nigerian heat.',
        category: 'Gadgets',
        shortDescription: 'Beat the heat with this slim rechargeable fan',
        quantity: 1),
  ];

  final List<Product> _drinkProducts = [
    Product(
        id: 'd1',
        name: 'Coca-Cola Classic pack',
        image: 'assets/cocacola_park.jpg',
        price: 4800,
        description: 'Refreshing Coca-Cola Classic.',
        category: 'Drinks',
        shortDescription: 'Classic Coca-Cola, refreshing and satisfying.',
        quantity: 1),
    Product(
        id: 'd2',
        name: 'Sprite Lemon-Lime pack',
        image: 'assets/sprite_drink.jpg',
        price: 4800,
        description: 'Crisp and refreshing Sprite.',
        category: 'Drinks',
        shortDescription: 'Crisp Sprite, lemon-lime refreshment.',
        quantity: 1),
    Product(
        id: 'd3',
        name: 'Maltina Malt Drink pack',
        image: 'assets/maltina_drink.jpg',
        price: 6500,
        description: 'Rich and malty Maltina, packed with nutrients.',
        category: 'Drinks',
        shortDescription: 'Nutritious Maltina, rich malt flavor.',
        quantity: 1),
    Product(
        id: 'd4',
        name: 'Maltina Can Packs',
        image: 'assets/maltina_can_drink.jpg',
        price: 5000,
        description: 'Convenient Maltina in a can, perfect for on-the-go.',
        category: 'Drinks',
        shortDescription: 'Convenient Maltina in a can.',
        quantity: 1),
    Product(
        id: 'd5',
        name: 'Fanta Orange Pack',
        image: 'assets/Fanta_drink packs.jpg',
        price: 4800,
        description: 'Refreshing Fanta Orange.',
        category: 'Drinks',
        shortDescription: 'Refreshing Fanta Orange drink.',
        quantity: 1),
  ];

  final List<Product> _clothingProducts = [
    Product(
        id: 'c1',
        name: 'Classic Jeans Trouser',
        image: 'assets/bazaarflow.cloth.2.jpg',
        price: 25000,
        description:
            'Premium quality classic jeans trouser, comfortable and stylish, available in all sizes.',
        category: 'Clothing',
        shortDescription: 'Crisp classic jeans, everyday essential',
        quantity: 1),
    Product(
        id: 'c2',
        name: 'Blue Boxy T-shirt / Boxy Fit Tee',
        image: 'assets/bazaarflow.cloth.3.jpg',
        price: 13000,
        description:
            'Blue Boxy BB Drip Logo Tee – Embossed melting BB design, soft cotton, dropped shoulders, pure street luxury energy.',
        category: 'Clothing',
        shortDescription:
            'Soft cotton boxy tee with embossed logo, streetwear essential',
        quantity: 1),
    Product(
        id: 'c3',
        name:
            '"WITH GOD" Premium Sleeveless Muscle Tee – Light Blue Streetwear',
        image: 'assets/bazaarflow.cloth.4.jpg',
        price: 13000,
        description:
            'Premium sleeveless muscle tee with bold WITH GOD print, soft breathable fabric, perfect for gym and streetwear looks.',
        category: 'Clothing',
        shortDescription: 'Bold sleeveless muscle tee, streetwear & gym ready',
        quantity: 1),
    Product(
        id: 'c4',
        name: 'REPLAY 1981 Luxury Oversized Graphic Tee',
        image: 'assets/bazaarflow.cloth.5.jpg',
        extraImages: [
          'assets/bazaarflow.cloth.4.1.webp',
        ],
        price: 13000,
        description:
            'High-quality oversized graphic tee with REPLAY 1981 print. Breathable cotton fabric that feels soft on the skin.',
        category: 'Clothing',
        shortDescription:
            'High-quality, breathable cotton oversized graphic tee',
        quantity: 1),
    Product(
        id: 'c5',
        name:
            'Premium "California Los Angeles" Oversized White Tee – Varsity Style',
        image: 'assets/bazaarflow.cloth.6.jpg',
        price: 13000,
        description:
            ''' Add a clean, classic vibe to your wardrobe with this high-quality California Los Angeles graphic t-shirt. It features a timeless varsity-inspired design that never goes out of style.

Design: Bold red "CALIFORNIA" and "LOS ANGELES" print with a vintage "EST. 1776" badge.

Fit: Trendy oversized, boxy fit with dropped shoulders for a relaxed, urban look.

Fabric: Heavyweight premium cotton—breathable, durable, and feels expensive.

Neckline: Sturdy ribbed crew neck that keeps its shape after washing.

Style: Perfect for pairing with baggy jeans, shorts, or cargos. Great for both men and women (Unisex).

Condition: Brand New / Top Quality.''',
        category: 'Clothing',
        shortDescription:
            'Iconic REPLAY 1981 branding, premium streetwear feel',
        quantity: 1),
    Product(
        id: 'c6',
        name:
            'Premium "HEARTBEAT" Minimalist Oversized Tee – Sleek Black Streetwear',
        image: 'assets/bazaarflow.cloth.7a.webp',
        extraImages: ['assets/bazaarflow.cloth.7.jpg'],
        price: 13000,
        description:
            ''' Keep it simple and sharp with this premium Heartbeat graphic tee. Designed for a clean, minimalist aesthetic, this shirt is perfect for anyone who wants high-quality streetwear that stands out quietly.

Design: Features a crisp, white "HEARTBEAT" linear graphic across the chest for a modern, sleek look.

Fit: Trendy oversized/boxy fit with dropped shoulders—gives you that effortless urban silhouette.

Fabric: High-grade, heavyweight cotton that is soft to the touch and holds its shape perfectly.

Neckline: Durable ribbed crew neck—built to last and resist stretching.

Style: A versatile "everyday" essential. Looks incredible paired with chains, cargo pants, or light-wash denim.

Condition: Brand New / Premium Quality.
Night Out Vibe: Mention that because it's black and sleek, it’s great for evening hangouts or clubbing outfits.''',
        category: 'Clothing',
        shortDescription:
            'Iconic REPLAY 1981 branding, premium streetwear feel',
        quantity: 1),
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _tabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _headerFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut));
    _headerAnim.forward();
    _searchController.addListener(() => _performSearch(_searchController.text));
    _initializeApp();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _ordersSubscription?.cancel();
    _headerAnim.dispose();
    _tabAnim.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FIREBASE
  // ═══════════════════════════════════════════════════════════════════════
  void _initializeApp() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      await _checkUserAuth();
      await _initializeFirestore();
      await _loadUserOrders();
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _firestoreError = e.toString();
          _firestoreStatus = 'Initialization Failed';
        });
    }
  }

  Future<void> _checkUserAuth() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isUserSignedIn = user != null;
        });
        if (user != null) _loadUserOrders();
      }
    });
    _currentUser = FirebaseAuth.instance.currentUser;
    _isUserSignedIn = _currentUser != null;
  }

  Future<void> _initializeFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('test').limit(1).get();
      if (mounted)
        setState(() {
          _isFirestoreConnected = true;
          _firestoreStatus = 'Connected';
          _firestoreError = null;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _isFirestoreConnected = false;
          _firestoreStatus = 'Connection Failed';
          _firestoreError = e.toString();
        });
    }
  }

  Future<void> _loadUserOrders() async {
    if (!_isUserSignedIn) {
      if (mounted)
        setState(() {
          _orders = [];
          _isLoading = false;
        });
      return;
    }
    try {
      _ordersStream = _firestoreService.getUserOrders(_currentUser!.uid);
      _ordersSubscription?.cancel();
      _ordersSubscription = _ordersStream!.listen(
        (orders) {
          if (mounted)
            setState(() {
              _orders = orders;
              _isLoading = false;
            });
        },
        onError: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
      );
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CART
  // ═══════════════════════════════════════════════════════════════════════
  int get cartItemCount => _cartItems.fold(0, (s, i) => s + i.quantity);

  void _addToCart(Product product, {int? customQuantity}) {
    HapticFeedback.lightImpact();
    final qty = customQuantity ?? product.quantity;
    setState(() {
      final idx = _cartItems.indexWhere((i) => i.product.id == product.id);
      if (idx >= 0) {
        _cartItems[idx] =
            CartItem(product: _cartItems[idx].product, quantity: qty);
      } else {
        _cartItems.add(CartItem(product: product, quantity: qty));
      }
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text('${product.name} added!',
                overflow: TextOverflow.ellipsis)),
      ]),
      backgroundColor: _D.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 1),
      action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => _showCart(context)),
    ));
  }

  void _removeFromCart(String id) {
    HapticFeedback.lightImpact();
    setState(() => _cartItems.removeWhere((i) => i.product.id == id));
  }

  void _clearCart() => setState(() => _cartItems.clear());

  void _updateCartQuantity(Product product, int qty) {
    setState(() {
      final idx = _cartItems.indexWhere((i) => i.product.id == product.id);
      if (idx < 0) return;
      if (qty > 0)
        _cartItems[idx] =
            CartItem(product: _cartItems[idx].product, quantity: qty);
      else
        _cartItems.removeAt(idx);
    });
  }

  void _updateProductQuantity(Product product, int qty) {
    setState(() {
      for (var shop in _shops) {
        final i = shop.products.indexWhere((p) => p.id == product.id);
        if (i != -1) shop.products[i].quantity = qty;
      }
      final gi = _gadgetProducts.indexWhere((p) => p.id == product.id);
      if (gi != -1) _gadgetProducts[gi].quantity = qty;
      final di = _drinkProducts.indexWhere((p) => p.id == product.id);
      if (di != -1) _drinkProducts[di].quantity = qty;
      final ci = _clothingProducts.indexWhere((p) => p.id == product.id);
      if (ci != -1) _clothingProducts[ci].quantity = qty;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════════════════
  void _performSearch(String q) => setState(() {
        _searchQuery = q.toLowerCase().trim();
        _isSearching = _searchQuery.isNotEmpty;
      });

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
    });
    _searchFocus.unfocus();
  }

  List<Product> _getDisplayProducts() {
    List<Product> base;
    switch (_selectedTabIndex) {
      case 1:
        base = _gadgetProducts;
        break;
      case 2:
        base = _drinkProducts;
        break;
      case 3:
        base = _clothingProducts;
        break;
      default:
        return [];
    }
    if (!_isSearching) return base;
    return base
        .where((p) =>
            p.name.toLowerCase().contains(_searchQuery) ||
            (p.shortDescription?.toLowerCase().contains(_searchQuery) ??
                false) ||
            p.description.toLowerCase().contains(_searchQuery))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════
  void _showCart(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CartBottomSheet(
        cartItems: _cartItems,
        removeFromCart: _removeFromCart,
        clearCart: _clearCart,
        updateQuantity: _updateCartQuantity,
        onCheckout: _navigateToCheckout,
      ),
    );
  }

  void _navigateToCheckout() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Your cart is empty!')));
      return;
    }
    if (!_isUserSignedIn) {
      _showLoginRequiredDialog();
      return;
    }
    final total =
        _cartItems.fold(0.0, (s, i) => s + i.product.price * i.quantity);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CheckoutPage(
                  cartItems: _cartItems,
                  totalAmount: total,
                  currentUser: _currentUser,
                  onOrderPlaced: (_) {
                    setState(() {
                      _cartItems.clear();
                      for (var shop in _shops)
                        for (var p in shop.products) p.quantity = 1;
                      for (var p in _gadgetProducts) p.quantity = 1;
                      for (var p in _drinkProducts) p.quantity = 1;
                      for (var p in _clothingProducts) p.quantity = 1;
                    });
                  },
                )));
  }

  void _showLoginRequiredDialog() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Login Required',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text('You need to sign in to place an order.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToLogin();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _D.blue700,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Sign In',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ));
  }

  void _navigateToLogin() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login page would open here')));

  void _navigateToOrderHistory() {
    if (!_isUserSignedIn) {
      _showLoginRequiredDialog();
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OrderHistoryPage(
                orders: _orders,
                onReorder: _reorderItems,
                ordersStream: _ordersStream)));
  }

  void _reorderItems(Orders order) {
    if (!_isUserSignedIn) {
      _showLoginRequiredDialog();
      return;
    }
    setState(() {
      _cartItems.clear();
      for (var item in order.items) {
        final idx =
            _cartItems.indexWhere((c) => c.product.id == item.product.id);
        if (idx >= 0)
          _cartItems[idx] = CartItem(
              product: _cartItems[idx].product,
              quantity: _cartItems[idx].quantity + item.quantity);
        else
          _cartItems
              .add(CartItem(product: item.product, quantity: item.quantity));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Added ${order.items.length} items to cart!'),
      action: SnackBarAction(label: 'Checkout', onPressed: _navigateToCheckout),
    ));
  }

  // ── ★ NEW: Navigate to clothing detail ──────────────────────────────────
  void _openClothingDetail(Product product) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClothingDetailScreen(
          product: product,
          cartItems: _cartItems,
          onAddToCart: _addToCart,
          onRemoveFromCart: _removeFromCart,
        ),
      ),
    ).then((_) {
      // Refresh cart state when returning from detail screen
      setState(() {});
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _D.surface,
      drawer: const MyDrawer(),
      extendBody: true,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                      opacity: _headerFade, child: _buildAppBar()),
                ),
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      SliverToBoxAdapter(child: _buildGreetingBanner()),
                      SliverToBoxAdapter(child: _buildSearchBar()),
                      SliverPersistentHeader(
                        delegate: _StickyTabsDelegate(
                          tabs: _tabs,
                          selectedIndex: _selectedTabIndex,
                          onTabChanged: (i) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedTabIndex = i;
                              _clearSearch();
                            });
                          },
                        ),
                        pinned: true,
                      ),
                      SliverToBoxAdapter(child: _buildCurrentTabContent()),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBackground() {
    return Column(children: [
      Container(
          height: 300,
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_D.gradTop, _D.gradMid, _D.gradLow]))),
      Expanded(child: Container(color: _D.surface)),
    ]);
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Builder(
              builder: (ctx) => _AppBarButton(
                  icon: Icons.menu_rounded,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Scaffold.of(ctx).openDrawer();
                  })),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bazaarflow',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1)),
                Row(children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: _isFirestoreConnected
                              ? _D.amber
                              : Colors.red.shade300,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(
                      _isUserSignedIn
                          ? 'Hi, ${_currentUser?.email?.split('@').first ?? 'User'} 👋'
                          : 'Browse as Guest',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ],
            ),
          ),
          _AppBarButton(
              icon: Icons.notifications_rounded,
              badge: _orders.where((o) => o.status == 'Pending').length,
              onTap: _navigateToOrderHistory),
          const SizedBox(width: 8),
          _AppBarButton(
              icon: Icons.shopping_bag_rounded,
              badge: cartItemCount,
              badgeColor: _D.amber,
              onTap: () => _showCart(context)),
        ],
      ),
    );
  }

  Widget _buildGreetingBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('What are you\ncraving today?',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: _D.amber,
                            borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.electric_bolt_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Fast delivery · ~35 min',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1.5)),
                    child: const Icon(Icons.delivery_dining_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                      width: 64,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                              value: 0.65,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              color: _D.amber,
                              minHeight: 6))),
                  const SizedBox(height: 4),
                  const Text('65%',
                      style: TextStyle(color: Colors.white70, fontSize: 10)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: _D.blue700.withOpacity(0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ]),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          style: const TextStyle(fontSize: 14, color: _D.ink),
          decoration: InputDecoration(
            hintText: 'Search food, gadgets, drinks, clothing…',
            hintStyle: const TextStyle(color: _D.inkLight, fontSize: 14),
            prefixIcon:
                const Icon(Icons.search_rounded, color: _D.blue600, size: 22),
            suffixIcon: _isSearching
                ? GestureDetector(
                    onTap: _clearSearch,
                    child: const Icon(Icons.cancel_rounded,
                        color: _D.inkLight, size: 20))
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildFoodTab();
      case 3:
        return _buildOtherTab();
      default:
        final products = _getDisplayProducts();
        if (products.isEmpty && _isSearching) return _buildNoResults();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          itemCount: products.length,
          itemBuilder: (_, i) => _buildProductCard(products[i]),
        );
    }
  }

  // ── Food tab (unchanged) ────────────────────────────────────────────────
  Widget _buildFoodTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            Text('${_shops.length} Restaurants',
                style: const TextStyle(
                    fontSize: 13,
                    color: _D.inkMid,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _D.blue50, borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.tune_rounded, color: _D.blue700, size: 13),
                SizedBox(width: 4),
                Text('Filter',
                    style: TextStyle(
                        fontSize: 12,
                        color: _D.blue700,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _shops.length,
          itemBuilder: (_, i) => _buildShopCard(_shops[i]),
        ),
      ],
    );
  }

  Widget _buildShopCard(Shop shop) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => KitchenScreen(
                    shop: shop,
                    onAddToCart: _addToCart,
                    onUpdateQuantity: _updateProductQuantity,
                    cartItems: _cartItems)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: _D.blue700.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Image.asset(shop.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: _D.blue100,
                              child: Center(
                                  child: Icon(Icons.store_rounded,
                                      size: 50, color: _D.blue500)))))),
              Positioned.fill(
                  child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(22)),
                      child: Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.45)
                          ]))))),
              Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: shop.isOpen ? _D.green : Colors.red.shade500,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(shop.isOpen ? 'Open' : 'Closed',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700))
                      ]))),
              Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.schedule_rounded,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text('${shop.deliveryTime} min',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600))
                      ]))),
            ]),
            Padding(
              padding: const EdgeInsets.all(16),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                              color: _D.blue700.withOpacity(0.15),
                              blurRadius: 10)
                        ]),
                    child: ClipOval(
                        child: Image.asset(shop.logoImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                color: _D.blue100,
                                child: Icon(Icons.store_rounded,
                                    color: _D.blue500, size: 24))))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Expanded(
                            child: Text(shop.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _D.ink,
                                    letterSpacing: -0.2))),
                        if (shop.isVerified)
                          Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color: _D.blue50, shape: BoxShape.circle),
                              child: const Icon(Icons.verified_rounded,
                                  color: _D.blue700, size: 14)),
                      ]),
                      const SizedBox(height: 2),
                      Text(shop.ownerName,
                          style:
                              const TextStyle(fontSize: 12, color: _D.inkMid)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFFFDE68A))),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.star_rounded,
                                  color: _D.amber, size: 13),
                              const SizedBox(width: 3),
                              Text('${shop.rating}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF92400E))),
                              Text(' (${shop.reviewCount})',
                                  style: const TextStyle(
                                      fontSize: 11, color: _D.inkLight))
                            ])),
                        const SizedBox(width: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                                color: _D.green50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFFA7F3D0))),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.delivery_dining_rounded,
                                  color: _D.green, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                  shop.deliveryFee == 0
                                      ? 'Free'
                                      : '₦${shop.deliveryFee}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _D.green))
                            ])),
                      ]),
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: shop.categories
                              .map((cat) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: _D.blue50,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Text(cat,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: _D.blue700,
                                          fontWeight: FontWeight.w500))))
                              .toList()),
                    ])),
              ]),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: _D.surface, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.attach_money_rounded,
                    size: 14, color: _D.inkMid),
                const SizedBox(width: 3),
                Text('Min ₦${shop.minimumOrder}',
                    style: const TextStyle(fontSize: 12, color: _D.inkMid)),
                const Spacer(),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [_D.blue800, _D.blue600]),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Order Now',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 13)
                    ])),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ── ★ UPDATED: Product card — clothing opens detail, others work as before ──
  Widget _buildProductCard(Product product) {
    final cartItem = _cartItems.firstWhere((i) => i.product.id == product.id,
        orElse: () => CartItem(product: product, quantity: 0));
    final isInCart = cartItem.quantity > 0;
    final qty = isInCart ? cartItem.quantity : product.quantity;
    final isCloth = product.category == 'Clothing';

    return GestureDetector(
      // ★ Clothing taps open the detail screen
      onTap: isCloth ? () => _openClothingDetail(product) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: _D.blue700.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
          // ★ Subtle blue border on clothing cards to hint they are tappable
          border: isCloth ? Border.all(color: _D.blue100, width: 1.5) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: product.image.startsWith('http')
                          ? Image.network(product.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _productImageError(product))
                          : Image.asset(product.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _productImageError(product)),
                    ),
                  ),
                  // ★ "View" badge on clothing images
                  if (isCloth)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                            color: _D.blue700.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_rounded,
                                  color: Colors.white, size: 10),
                              SizedBox(width: 3),
                              Text('View',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                            ]),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(product.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _D.ink,
                            height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    // Description
                    Text(product.shortDescription ?? product.description,
                        style: const TextStyle(
                            fontSize: 12, color: _D.inkMid, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),

                    // Price
                    Row(children: [
                      Text('₦${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _D.blue700,
                              letterSpacing: -0.3)),
                      if (qty > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: _D.green50,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                                '= ₦${(product.price * qty).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _D.green))),
                      ],
                    ]),
                    const SizedBox(height: 10),

                    // Controls
                    Row(children: [
                      // Qty stepper (hidden for clothing — user picks size/qty on detail screen)
                      if (!isCloth) ...[
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                              color: _D.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _D.border)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            _StepperBtn(
                                icon: Icons.remove_rounded,
                                enabled: qty > 1,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  final nq = qty - 1;
                                  _updateProductQuantity(product, nq);
                                  if (isInCart)
                                    _updateCartQuantity(product, nq);
                                }),
                            SizedBox(
                                width: 28,
                                child: Center(
                                    child: Text('$qty',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: _D.ink)))),
                            _StepperBtn(
                                icon: Icons.add_rounded,
                                enabled: true,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  final nq = qty + 1;
                                  _updateProductQuantity(product, nq);
                                  if (isInCart)
                                    _updateCartQuantity(product, nq);
                                }),
                          ]),
                        ),
                        const Spacer(),
                        isInCart
                            ? _CartActionBtn(
                                label: 'Remove',
                                icon: Icons.remove_shopping_cart_rounded,
                                isRemove: true,
                                onTap: () => _removeFromCart(product.id))
                            : _CartActionBtn(
                                label: 'Add',
                                icon: Icons.add_shopping_cart_rounded,
                                isRemove: false,
                                onTap: () => _addToCart(product)),
                      ] else ...[
                        // ★ Clothing: show "See Details" button instead of stepper
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openClothingDetail(product),
                            child: Container(
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [_D.blue800, _D.blue600]),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color: _D.blue700.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ],
                              ),
                              child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.checkroom_rounded,
                                        color: Colors.white, size: 14),
                                    SizedBox(width: 6),
                                    Text('See Details',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded,
                                        color: Colors.white70, size: 13),
                                  ]),
                            ),
                          ),
                        ),
                        if (isInCart) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                                color: _D.green50,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: const Color(0xFFA7F3D0))),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: _D.green, size: 14),
                              const SizedBox(width: 4),
                              const Text('In Cart',
                                  style: TextStyle(
                                      color: _D.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ],
                      ],
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productImageError(Product product) {
    IconData ico = Icons.local_drink_rounded;
    if (product.category == 'Gadgets') ico = Icons.devices_rounded;
    if (product.category == 'Clothing') ico = Icons.checkroom_rounded;
    return Container(
        color: _D.blue50,
        child: Center(child: Icon(ico, color: _D.blue500, size: 32)));
  }

  // ── ★ UPDATED: Other tab uses clothing product cards with detail nav ───
  Widget _buildOtherTab() {
    final products = _isSearching
        ? _clothingProducts
            .where((p) =>
                p.name.toLowerCase().contains(_searchQuery) ||
                (p.shortDescription?.toLowerCase().contains(_searchQuery) ??
                    false) ||
                p.description.toLowerCase().contains(_searchQuery))
            .toList()
        : _clothingProducts;

    if (products.isEmpty && _isSearching) return _buildNoResults();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            Text('${_clothingProducts.length} Clothing Items',
                style: const TextStyle(
                    fontSize: 13,
                    color: _D.inkMid,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _D.blue50, borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.tune_rounded, color: _D.blue700, size: 13),
                SizedBox(width: 4),
                Text('Filter',
                    style: TextStyle(
                        fontSize: 12,
                        color: _D.blue700,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
        // ★ Info banner — tells user they can tap for details
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _D.blue50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _D.blue100),
            ),
            child: const Row(children: [
              Icon(Icons.touch_app_rounded, color: _D.blue700, size: 16),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Tap any item to see full details, photos, sizes & colors',
                      style: TextStyle(
                          fontSize: 12,
                          color: _D.blue700,
                          fontWeight: FontWeight.w500))),
            ]),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          itemCount: products.length,
          itemBuilder: (_, i) => _buildProductCard(products[i]),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(children: [
        Icon(Icons.search_off_rounded, size: 80, color: _D.blue100),
        const SizedBox(height: 16),
        Text('No results for "$_searchQuery"',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _D.ink),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Try different keywords',
            style: TextStyle(fontSize: 13, color: _D.inkMid)),
        const SizedBox(height: 20),
        GestureDetector(
            onTap: _clearSearch,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    color: _D.blue50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _D.blue100)),
                child: const Text('Clear Search',
                    style: TextStyle(
                        color: _D.blue700, fontWeight: FontWeight.w600)))),
      ]),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
            child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: const Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                          color: _D.blue700, strokeWidth: 3)),
                  SizedBox(height: 14),
                  Text('Loading…',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _D.ink))
                ]))));
  }

  Widget _buildBottomNavBar() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.grid_view_rounded, 'label': 'Categories'},
      {'icon': Icons.shopping_bag_rounded, 'label': 'Cart'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Orders'},
    ];
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: _D.blue700.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = _bottomNavIndex == i;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _bottomNavIndex = i);
                  if (i == 2) _showCart(context);
                  if (i == 3) _navigateToOrderHistory();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: isActive ? _D.blue50 : Colors.transparent,
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Stack(clipBehavior: Clip.none, children: [
                      Icon(items[i]['icon'] as IconData,
                          color: isActive ? _D.blue700 : _D.inkLight, size: 24),
                      if (i == 2 && cartItemCount > 0)
                        Positioned(
                            top: -4,
                            right: -6,
                            child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                    color: _D.amber, shape: BoxShape.circle),
                                child: Text('$cartItemCount',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800)))),
                    ]),
                    const SizedBox(height: 3),
                    Text(items[i]['label'] as String,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? _D.blue700 : _D.inkLight)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STICKY TABS DELEGATE
// ═══════════════════════════════════════════════════════════════════════════
class _StickyTabsDelegate extends SliverPersistentHeaderDelegate {
  final List<Map<String, dynamic>> tabs;
  final int selectedIndex;
  final void Function(int) onTabChanged;

  const _StickyTabsDelegate(
      {required this.tabs,
      required this.selectedIndex,
      required this.onTabChanged});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: shrinkOffset > 0 ? Colors.white : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (_, i) {
          final isActive = selectedIndex == i;
          return GestureDetector(
            onTap: () => onTabChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(colors: [_D.blue800, _D.blue600])
                    : null,
                color: isActive ? null : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                            color: _D.blue700.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3))
                      ]
                    : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(tabs[i]['icon'] as IconData,
                    color: isActive ? Colors.white : _D.inkMid, size: 15),
                const SizedBox(width: 6),
                Text(tabs[i]['label'] as String,
                    style: TextStyle(
                        color: isActive ? Colors.white : _D.inkMid,
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500)),
              ]),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTabsDelegate old) =>
      old.selectedIndex != selectedIndex;
}

// ═══════════════════════════════════════════════════════════════════════════
// SMALL REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════
class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  final Color badgeColor;
  final VoidCallback onTap;
  const _AppBarButton(
      {required this.icon,
      required this.onTap,
      this.badge = 0,
      this.badgeColor = Colors.red});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withOpacity(0.3), width: 1)),
            child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  if (badge > 0)
                    Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                                color: badgeColor, shape: BoxShape.circle),
                            child: Text('$badge',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800))))
                ])));
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepperBtn(
      {required this.icon, required this.enabled, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            child: Icon(icon,
                size: 15, color: enabled ? _D.blue700 : _D.inkLight)));
  }
}

class _CartActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isRemove;
  final VoidCallback onTap;
  const _CartActionBtn(
      {required this.label,
      required this.icon,
      required this.isRemove,
      required this.onTap});
  @override
  State<_CartActionBtn> createState() => _CartActionBtnState();
}

class _CartActionBtnState extends State<_CartActionBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final bg = widget.isRemove ? const Color(0xFFFEF2F2) : _D.blue700;
    final fg = widget.isRemove ? Colors.red.shade600 : Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: widget.isRemove
              ? (_pressed ? Colors.red.shade50 : bg)
              : (_pressed ? _D.blue800 : bg),
          borderRadius: BorderRadius.circular(14),
          border:
              widget.isRemove ? Border.all(color: Colors.red.shade200) : null,
          boxShadow: widget.isRemove || _pressed
              ? []
              : [
                  BoxShadow(
                      color: _D.blue700.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, color: fg, size: 14),
          const SizedBox(width: 4),
          Text(widget.label,
              style: TextStyle(
                  color: fg, fontSize: 12, fontWeight: FontWeight.w700))
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CART BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════
class CartBottomSheet extends StatelessWidget {
  final List<CartItem> cartItems;
  final Function(String) removeFromCart;
  final VoidCallback clearCart;
  final Function(Product, int) updateQuantity;
  final VoidCallback onCheckout;

  const CartBottomSheet(
      {super.key,
      required this.cartItems,
      required this.removeFromCart,
      required this.clearCart,
      required this.updateQuantity,
      required this.onCheckout});

  double get totalAmount =>
      cartItems.fold(0.0, (s, i) => s + i.product.price * i.quantity);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _D.border,
                      borderRadius: BorderRadius.circular(2)))),
          Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _D.blue50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.shopping_bag_rounded,
                    color: _D.blue700, size: 20)),
            const SizedBox(width: 10),
            const Text('Your Cart',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: _D.ink)),
            const Spacer(),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _D.blue50, borderRadius: BorderRadius.circular(20)),
                child: Text(
                    '${cartItems.length} item${cartItems.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _D.blue700,
                        fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 16),
          if (cartItems.isEmpty)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(children: [
                  Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          color: _D.blue50, shape: BoxShape.circle),
                      child: const Icon(Icons.shopping_bag_outlined,
                          size: 40, color: _D.blue100)),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _D.ink)),
                  const SizedBox(height: 6),
                  const Text('Add items to get started!',
                      style: TextStyle(fontSize: 13, color: _D.inkMid))
                ]))
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: cartItems.length,
                itemBuilder: (_, i) {
                  final item = cartItems[i];
                  final p = item.product;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: _D.surface,
                        borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                              width: 52,
                              height: 52,
                              child: p.image.startsWith('http')
                                  ? Image.network(p.image,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                          color: _D.blue50,
                                          child: const Icon(Icons.shopping_bag,
                                              color: _D.blue300)))
                                  : Image.asset(p.image,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                          color: _D.blue50,
                                          child: const Icon(Icons.shopping_bag,
                                              color: _D.blue300))))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(p.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _D.ink),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('₦${p.price.toStringAsFixed(0)} each',
                                style: const TextStyle(
                                    fontSize: 11, color: _D.inkMid))
                          ])),
                      Container(
                          height: 30,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: _D.border)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: item.quantity > 1
                                    ? () => updateQuantity(p, item.quantity - 1)
                                    : null,
                                child: Container(
                                    width: 28,
                                    height: 30,
                                    alignment: Alignment.center,
                                    child: Icon(Icons.remove_rounded,
                                        size: 13,
                                        color: item.quantity > 1
                                            ? _D.blue700
                                            : _D.inkLight))),
                            SizedBox(
                                width: 24,
                                child: Center(
                                    child: Text('${item.quantity}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _D.ink)))),
                            GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    updateQuantity(p, item.quantity + 1),
                                child: Container(
                                    width: 28,
                                    height: 30,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.add_rounded,
                                        size: 13, color: _D.blue700))),
                          ])),
                      const SizedBox(width: 6),
                      GestureDetector(
                          onTap: () => removeFromCart(p.id),
                          child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.red, size: 14))),
                    ]),
                  );
                },
              ),
            ),
          if (cartItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _D.blue50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _D.border)),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal',
                          style: TextStyle(fontSize: 13, color: _D.inkMid)),
                      Text('₦${totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _D.ink))
                    ]),
                const SizedBox(height: 4),
                const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delivery',
                          style: TextStyle(fontSize: 13, color: _D.inkMid)),
                      Text('₦700',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _D.ink))
                    ]),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: _D.border, height: 1)),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _D.ink)),
                      Text('₦${(totalAmount + 700).toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: _D.blue700,
                              letterSpacing: -0.5))
                    ]),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              GestureDetector(
                  onTap: clearCart,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                          color: _D.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _D.border)),
                      child: const Text('Clear',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _D.inkMid)))),
              const SizedBox(width: 10),
              Expanded(
                  child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onCheckout();
                      },
                      child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [_D.blue800, _D.blue600]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: _D.blue700.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ]),
                          child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.flash_on_rounded,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text('Checkout',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800))
                              ])))),
            ]),
          ],
        ],
      ),
    );
  }
}
