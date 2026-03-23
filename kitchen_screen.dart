import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iyadunni_shopmore/component.dart/cart_items.dart';
import 'package:iyadunni_shopmore/component.dart/product.dart';
import 'package:iyadunni_shopmore/component.dart/shop_model.dart';

class KitchenScreen extends StatefulWidget {
  final Shop shop;
  final Function(Product, {int? customQuantity}) onAddToCart;
  final Function(Product, int) onUpdateQuantity;
  final List<CartItem> cartItems;

  const KitchenScreen({
    super.key,
    required this.shop,
    required this.onAddToCart,
    required this.onUpdateQuantity,
    required this.cartItems,
  });

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen>
    with TickerProviderStateMixin {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ─── LOCAL QUANTITY + CART STATE (instant UI response) ───────────────────
  // Keys are product.id. Quantities start at 1 (the picker default).
  final Map<String, int> _localQuantities = {};
  // Tracks which products have been added to cart locally.
  final Map<String, bool> _localInCart = {};

  // ─── SYNC helpers ─────────────────────────────────────────────────────────
  /// Returns the quantity to display for a product.
  int _qty(Product p) => _localQuantities[p.id] ?? 1;

  /// Returns whether a product is in the cart (local state wins).
  bool _inCart(Product p) =>
      _localInCart[p.id] ??
      widget.cartItems.any((c) => c.product.id == p.id && c.quantity > 0);

  // Seed local state from parent cartItems whenever the widget updates.
  void _syncFromParent() {
    for (final item in widget.cartItems) {
      if (item.quantity > 0) {
        _localInCart[item.product.id] = true;
        // Only seed quantity if we haven't set it locally yet.
        _localQuantities.putIfAbsent(item.product.id, () => item.quantity);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _syncFromParent();
    _filteredProducts = widget.shop.products;
    _searchController.addListener(_filterProducts);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(KitchenScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync whenever the parent passes fresh cartItems.
    _syncFromParent();
  }

  // ─── QUANTITY ACTIONS ─────────────────────────────────────────────────────
  void _increment(Product p) {
    HapticFeedback.lightImpact(); // works on both Android & iOS
    setState(() {
      _localQuantities[p.id] = _qty(p) + 1;
    });
    // If already in cart, tell parent immediately.
    if (_inCart(p)) {
      widget.onUpdateQuantity(p, _localQuantities[p.id]!);
    }
  }

  void _decrement(Product p) {
    if (_qty(p) <= 1) return;
    HapticFeedback.lightImpact();
    setState(() {
      _localQuantities[p.id] = _qty(p) - 1;
    });
    if (_inCart(p)) {
      widget.onUpdateQuantity(p, _localQuantities[p.id]!);
    }
  }

  void _addToCart(Product p) {
    HapticFeedback.mediumImpact();
    setState(() {
      _localInCart[p.id] = true;
    });
    widget.onAddToCart(p, customQuantity: _qty(p));

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${p.name} added to cart',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.green.shade600,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // ─── FILTER ───────────────────────────────────────────────────────────────
  void _filterProducts() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty && _selectedCategory == 'All') {
        _filteredProducts = widget.shop.products;
      } else {
        _filteredProducts = widget.shop.products.where((product) {
          final matchesSearch = query.isEmpty ||
              product.name.toLowerCase().contains(query) ||
              (product.shortDescription?.toLowerCase().contains(query) ??
                  false) ||
              product.description.toLowerCase().contains(query);
          final matchesCategory = _selectedCategory == 'All' ||
              product.category == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();
      }
    });
  }

  List<String> get _categories {
    final cats = widget.shop.products
        .map((p) => p.category)
        .where((c) => c != null && c.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList()
      ..sort();
    cats.insert(0, 'All');
    return cats;
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          // iOS momentum scrolling
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── HEADER ──────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.blue.shade700,
              // iOS-style back chevron
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                titlePadding:
                    const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                title: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          widget.shop.logoImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white,
                            child: Icon(Icons.store,
                                color: Colors.blue.shade700, size: 18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.shop.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      widget.shop.coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade700
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 60,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.shop.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 2))
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatChip(
                                  icon: Icons.star,
                                  label: widget.shop.rating.toString(),
                                  color: Colors.amber),
                              const SizedBox(width: 8),
                              _buildStatChip(
                                  icon: Icons.access_time,
                                  label: '${widget.shop.deliveryTime} min',
                                  color: Colors.white.withOpacity(0.2)),
                              const SizedBox(width: 8),
                              _buildStatChip(
                                  icon: Icons.delivery_dining,
                                  label: widget.shop.deliveryFee == 0
                                      ? 'Free'
                                      : '₦${widget.shop.deliveryFee}',
                                  color: Colors.green.withOpacity(0.9)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── SEARCH BAR ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'Search in ${widget.shop.name}...',
                      hintStyle:
                          TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon:
                          Icon(Icons.search, color: Colors.blue.shade700),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _filterProducts();
                              },
                              child: Icon(Icons.cancel,
                                  color: Colors.grey.shade400, size: 20),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            // ── CATEGORY CHIPS ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                            _filterProducts();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.blue.shade700.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── PRODUCTS (2-column, self-sizing rows) ───────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, rowIndex) {
                    final firstIndex = rowIndex * 2;
                    final secondIndex = firstIndex + 1;
                    final hasSecond = secondIndex < _filteredProducts.length;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ProductCard(
                              product: _filteredProducts[firstIndex],
                              quantity: _qty(_filteredProducts[firstIndex]),
                              isInCart: _inCart(_filteredProducts[firstIndex]),
                              onIncrement: () =>
                                  _increment(_filteredProducts[firstIndex]),
                              onDecrement: () =>
                                  _decrement(_filteredProducts[firstIndex]),
                              onAddToCart: () =>
                                  _addToCart(_filteredProducts[firstIndex]),
                              onViewCartDetails: () => _showCartItemDetails(
                                  _filteredProducts[firstIndex],
                                  _qty(_filteredProducts[firstIndex])),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: hasSecond
                                ? _ProductCard(
                                    product: _filteredProducts[secondIndex],
                                    quantity:
                                        _qty(_filteredProducts[secondIndex]),
                                    isInCart:
                                        _inCart(_filteredProducts[secondIndex]),
                                    onIncrement: () => _increment(
                                        _filteredProducts[secondIndex]),
                                    onDecrement: () => _decrement(
                                        _filteredProducts[secondIndex]),
                                    onAddToCart: () => _addToCart(
                                        _filteredProducts[secondIndex]),
                                    onViewCartDetails: () =>
                                        _showCartItemDetails(
                                            _filteredProducts[secondIndex],
                                            _qty(_filteredProducts[
                                                secondIndex])),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: (_filteredProducts.length / 2).ceil(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  // ─── STAT CHIP ────────────────────────────────────────────────────────────
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── BOTTOM SHEET ─────────────────────────────────────────────────────────
  void _showCartItemDetails(Product product, int quantity) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text('Item in Cart',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.asset(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.blue.shade50,
                        child:
                            Icon(Icons.fastfood, color: Colors.blue.shade300),
                      ),
                    ),
                  ),
                ),
                title: Text(product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text('Quantity: $quantity'),
                trailing: Text(
                  '₦${(product.price * quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Continue Shopping'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('View Cart'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PRODUCT CARD — extracted as its own StatelessWidget so setState on the
// parent never causes unnecessary rebuilds of unrelated cards.
// ═══════════════════════════════════════════════════════════════════════════
class _ProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final bool isInCart;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onAddToCart;
  final VoidCallback onViewCartDetails;

  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.isInCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAddToCart,
    required this.onViewCartDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── IMAGE ──────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 130,
              width: double.infinity,
              child: Image.asset(
                product.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.blue.shade50,
                  child: Center(
                    child: Icon(Icons.fastfood,
                        size: 40, color: Colors.blue.shade200),
                  ),
                ),
              ),
            ),
          ),

          // ── INFO ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                Text(
                  product.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Price
                Text(
                  '₦${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700),
                ),
                const SizedBox(height: 8),

                // ── QUANTITY ROW ─────────────────────────────────────────
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      // MINUS
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: quantity > 1 ? onDecrement : null,
                          child: Container(
                            height: 36,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.remove,
                              size: 16,
                              color: quantity > 1
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),

                      // COUNT
                      Text(
                        '$quantity',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),

                      // PLUS
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onIncrement,
                          child: Container(
                            height: 36,
                            alignment: Alignment.center,
                            child: Icon(Icons.add,
                                size: 16, color: Colors.blue.shade700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── ADD TO CART / IN CART BUTTON ─────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: isInCart
                      ? _InCartButton(
                          quantity: quantity,
                          onTap: onViewCartDetails,
                        )
                      : _AddToCartButton(onTap: onAddToCart),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add to Cart button with press animation ────────────────────────────────
class _AddToCartButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddToCartButton({required this.onTap});

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
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
        decoration: BoxDecoration(
          color: _pressed ? Colors.blue.shade900 : Colors.blue.shade700,
          borderRadius: BorderRadius.circular(19),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.blue.shade700.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 14, color: Colors.white),
            SizedBox(width: 5),
            Text(
              'Add to Cart',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ── In Cart button with press animation ───────────────────────────────────
class _InCartButton extends StatefulWidget {
  final int quantity;
  final VoidCallback onTap;
  const _InCartButton({required this.quantity, required this.onTap});

  @override
  State<_InCartButton> createState() => _InCartButtonState();
}

class _InCartButtonState extends State<_InCartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
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
        decoration: BoxDecoration(
          color: _pressed ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
              color: _pressed ? Colors.green.shade700 : Colors.green,
              width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle,
                size: 14,
                color: _pressed ? Colors.green.shade700 : Colors.green),
            const SizedBox(width: 4),
            Text(
              'In Cart (${widget.quantity})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _pressed ? Colors.green.shade700 : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
