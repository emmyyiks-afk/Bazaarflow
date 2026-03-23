import 'package:flutter/material.dart';
import 'package:iyadunni_shopmore/component.dart/product.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // 1. CONTROLLER - Required for search
  final TextEditingController _searchController = TextEditingController();

  // 2. VARIABLES
  String _searchQuery = '';
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();

    // Add listener for search
    _searchController.addListener(_onSearchChanged);
  }

  // 3. LOAD YOUR PRODUCTS
  Future<void> _loadProducts() async {
    // Your actual product list
    _allProducts = [
      Product(
        id: '1',
        name: 'Iyadunni Akara (Jumbo Special)',
        image: 'assets/image-5.jpg',
        price: 500.00,
        description: "Jumbo long akara with crayfish - extra crispy!",
        category: 'Food',
        shortDescription: 'Extra crispy & flavorful!',
      ),
      Product(
        id: '2',
        name: 'Pounded Yam and Vegetable soup',
        image: 'assets/images (2).jpeg',
        price: 500.00,
        description: 'Smooth pounded yam with rich vegetable soup',
        category: 'Food',
        shortDescription: 'Smooth and stretchy',
      ),
      Product(
        id: '3',
        name: 'Efo Riro with Pounded Yam',
        image: 'assets/Efo Riro nd pounded yam.jpg',
        price: 500.00,
        description: 'Savory spinach stew with assorted meat',
        category: 'Food',
        shortDescription: 'Rich spinach stew',
      ),
      Product(
        id: '4',
        name: 'Fried Rice',
        image: 'assets/Fried Rice.png',
        price: 400.00,
        description: 'Crispy fried rice with vegetables and liver',
        category: 'Food',
        shortDescription: 'Crispy fried rice',
      ),
      Product(
        id: '5',
        name: 'Jollof Rice',
        image: 'assets/Jollof Rice.jpg',
        price: 400.00,
        description: 'Spicy party jollof rice with chicken',
        category: 'Food',
        shortDescription: 'Spicy jollof rice',
      ),
      Product(
        id: '6',
        name: 'Amala and Ewedu Soup',
        image: 'assets/Emala_Ewedu soup.jpg',
        price: 400.00,
        description: 'Smooth amala with ewedu and assorted meat',
        category: 'Food',
        shortDescription: 'Earthy amala with ewedu',
      ),
      Product(
        id: '7',
        name: 'Amala and Egusi Soup',
        image: 'assets/Amala_Egusi soup.jpg',
        price: 400.00,
        description: 'Smooth amala with rich egusi soup',
        category: 'Food',
        shortDescription: 'Soft amala with egusi',
      ),
      Product(
        id: '8',
        name: 'Chicken and Chips',
        image: 'assets/chicken_chips_midi.jpg',
        price: 3200.00,
        description: 'Crispy fried chicken with golden chips',
        category: 'Food',
        shortDescription: 'Crispy chicken & chips',
      ),
      Product(
        id: '9',
        name: 'Chicken Shawarma',
        image: 'assets/chicken_shawarma.jpg',
        price: 2400.00,
        description: 'Spicy chicken shawarma with garlic sauce',
        category: 'Food',
        shortDescription: 'Juicy chicken shawarma',
      ),
    ];

    setState(() {
      _filteredProducts = List.from(_allProducts);
      _isLoading = false;
    });
  }

  // 4. SEARCH FUNCTION - This is the key part!
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _filterProducts();
    });
  }

  void _filterProducts() {
    if (_searchQuery.isEmpty) {
      // If search is empty, show all products
      _filteredProducts = List.from(_allProducts);
    } else {
      // Filter products based on search
      _filteredProducts = _allProducts.where((product) {
        final nameMatch = product.name.toLowerCase().contains(_searchQuery);
        final descMatch =
            product.description.toLowerCase().contains(_searchQuery);
        final shortDescMatch =
            product.shortDescription?.toLowerCase().contains(_searchQuery) ??
                false;

        // Debug print to see what's matching
        debugPrint('Searching: $_searchQuery - ${product.name}: $nameMatch');

        return nameMatch || descMatch || shortDescMatch;
      }).toList();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // SEARCH BOX - Your exact design
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Search for food, gadgets, drinks, and more",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.blue),
                ),
                onChanged: (value) {
                  // Alternative: Direct onChanged instead of listener
                  setState(() {
                    _searchQuery = value.toLowerCase().trim();
                    _filterProducts();
                  });
                },
              ),
            ),
          ),

          // RESULTS
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Start typing to search'
                : 'No results found for "$_searchQuery"',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try searching for: akara, rice, amala, chicken',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_filteredProducts[index]);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                color: Colors.blue.shade100,
                child: const Icon(Icons.fastfood, size: 40),
                // Replace with your actual image loading
              ),
            ),
          ),
          // Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.shortDescription ?? product.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Product Model
class Product {
  final String id;
  final String name;
  final String image;
  final double price;
  final String description;
  final String category;
  final String? shortDescription;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.description,
    required this.category,
    this.shortDescription,
  });
}
