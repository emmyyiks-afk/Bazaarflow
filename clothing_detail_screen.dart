import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iyadunni_shopmore/component.dart/product.dart';
import 'package:iyadunni_shopmore/component.dart/cart_items.dart';

// ── Design tokens (matching Bazaarflow) ──
const _kBlue = Color(0xFF1A3DC4);
const _kBlueDark = Color(0xFF0F2580);
const _kBlueMid = Color(0xFF2B4EE6);
const _kBlueLight = Color(0xFFEEF2FF);
const _kAmber = Color(0xFFF59E0B);
const _kGreen = Color(0xFF059669);
const _kGreen50 = Color(0xFFECFDF5);
const _kInk = Color(0xFF111827);
const _kInkMid = Color(0xFF6B7280);
const _kInkLight = Color(0xFF9CA3AF);
const _kSurface = Color(0xFFF5F7FF);
const _kBorder = Color(0xFFDDE5F7);

// ══════════════════════════════════════════════════════════════════
//  CLOTHING DETAIL SCREEN
// ══════════════════════════════════════════════════════════════════
class ClothingDetailScreen extends StatefulWidget {
  final Product product;
  final List<CartItem> cartItems;
  final Function(Product, {int? customQuantity}) onAddToCart;
  final Function(String) onRemoveFromCart;

  const ClothingDetailScreen({
    super.key,
    required this.product,
    required this.cartItems,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  });

  @override
  State<ClothingDetailScreen> createState() => _ClothingDetailScreenState();
}

class _ClothingDetailScreenState extends State<ClothingDetailScreen>
    with TickerProviderStateMixin {
  int _currentImageIndex = 0;
  int _selectedQty = 1;
  String? _selectedSize;
  String? _selectedColor;
  bool _descExpanded = false;
  late PageController _pageCtrl;
  late AnimationController _fadeAnim;
  late Animation<double> _fade;

  List<String> get _images {
    final extras = widget.product.extraImages ?? [];
    return [widget.product.image, ...extras];
  }

  // ── Arrow navigation helpers ──
  void _prevImage() {
    if (_currentImageIndex > 0) {
      HapticFeedback.lightImpact();
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextImage() {
    if (_currentImageIndex < _images.length - 1) {
      HapticFeedback.lightImpact();
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Mock details — extend Product model later to carry these ──
  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<String> _colors = ['Black', 'White', 'Navy', 'Grey', 'Brown'];
  final List<Map<String, String>> _specs = [
    {'label': 'Type', 'value': 'Streetwear'},
    {'label': 'Material', 'value': 'Cotton'},
    {'label': 'Gender', 'value': 'Unisex'},
    {'label': 'Condition', 'value': 'Brand New'},
    {'label': 'Style', 'value': 'Casual'},
    {'label': 'Brand', 'value': 'ShopMore'},
  ];

  bool get _isInCart =>
      widget.cartItems.any((i) => i.product.id == widget.product.id);

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _fadeAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _fadeAnim, curve: Curves.easeOut);
    _fadeAnim.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeAnim.dispose();
    super.dispose();
  }

  void _handleCartAction() {
    HapticFeedback.mediumImpact();
    if (_isInCart) {
      widget.onRemoveFromCart(widget.product.id);
      _showSnack('Removed from cart',
          isError: false, icon: Icons.remove_shopping_cart_rounded);
    } else {
      widget.product.quantity = _selectedQty;
      widget.onAddToCart(widget.product, customQuantity: _selectedQty);
    }
    setState(() {});
  }

  void _showSnack(String msg,
      {bool isError = false, IconData icon = Icons.check_circle_rounded}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: isError ? Colors.red : _kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 2),
    ));
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildImageGallery()),
                SliverToBoxAdapter(child: _buildInfoCard()),
                SliverToBoxAdapter(child: _buildSizeSelector()),
                SliverToBoxAdapter(child: _buildColorSelector()),
                SliverToBoxAdapter(child: _buildSpecs()),
                SliverToBoxAdapter(child: _buildDescription()),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomCTA(),
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
            ],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kInk, size: 18),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.bookmark_border_rounded,
                color: _kInk, size: 20),
            onPressed: () =>
                _showSnack('Saved to wishlist', icon: Icons.bookmark_rounded),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.share_rounded, color: _kInk, size: 20),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  // ── Image gallery ──────────────────────────────────────────────────────
  Widget _buildImageGallery() {
    final bool hasPrev = _currentImageIndex > 0;
    final bool hasNext = _currentImageIndex < _images.length - 1;

    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          // ── Image PageView ──
          PageView.builder(
            controller: _pageCtrl,
            itemCount: _images.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (_, i) {
              final img = _images[i];
              return img.startsWith('http')
                  ? Image.network(img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgError())
                  : Image.asset(img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgError());
            },
          ),

          // ── Gradient overlay ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),

          // ── LEFT arrow (only shown when more than 1 image) ──
          if (_images.length > 1)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: hasPrev ? 1.0 : 0.3,
                  child: GestureDetector(
                    onTap: hasPrev ? _prevImage : null,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: _kInk, size: 22),
                    ),
                  ),
                ),
              ),
            ),

          // ── RIGHT arrow (only shown when more than 1 image) ──
          if (_images.length > 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: hasNext ? 1.0 : 0.3,
                  child: GestureDetector(
                    onTap: hasNext ? _nextImage : null,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: _kInk, size: 22),
                    ),
                  ),
                ),
              ),
            ),

          // ── Photo count badge ──
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_camera_rounded,
                      color: Colors.white, size: 13),
                  const SizedBox(width: 4),
                  Text('${_currentImageIndex + 1} / ${_images.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          // ── Dot indicators ──
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              children: List.generate(
                _images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _currentImageIndex == i ? 20 : 7,
                  height: 7,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: _currentImageIndex == i
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // ── Brand New badge ──
          Positioned(
            top: 60,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Brand New',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgError() => Container(
        color: _kBlueLight,
        child: const Center(
          child: Icon(Icons.checkroom_rounded, color: _kBlue, size: 60),
        ),
      );

  // ── Info card ──────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.product.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _kInk,
                letterSpacing: -0.3,
              )),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '₦${widget.product.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _kBlue,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kGreen50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: _kGreen, size: 13),
                    SizedBox(width: 4),
                    Text('In Stock',
                        style: TextStyle(
                            color: _kGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (widget.product.shortDescription != null) ...[
            Text(widget.product.shortDescription!,
                style: const TextStyle(
                    fontSize: 13, color: _kInkMid, height: 1.5)),
            const SizedBox(height: 12),
          ],
          Divider(color: _kBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Quantity',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _kInk)),
              const Spacer(),
              _buildQtyStepper(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyStepper() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _selectedQty > 1
                ? () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedQty--);
                  }
                : null,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Icon(Icons.remove_rounded,
                  size: 16, color: _selectedQty > 1 ? _kBlue : _kInkLight),
            ),
          ),
          SizedBox(
            width: 36,
            child: Center(
              child: Text('$_selectedQty',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _kInk)),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedQty++);
            },
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: const Icon(Icons.add_rounded, size: 16, color: _kBlue),
            ),
          ),
        ],
      ),
    );
  }

  // ── Size selector ──────────────────────────────────────────────────────
  Widget _buildSizeSelector() {
    return _sectionCard(
      title: 'Select Size',
      trailing: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: const Text('Size Guide →',
            style: TextStyle(
                color: _kBlue, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _sizes.map((size) {
          final isSelected = _selectedSize == size;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedSize = size);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _kBlue : _kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? _kBlue : _kBorder,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: _kBlue.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : [],
              ),
              child: Text(size,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : _kInkMid,
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Color selector ─────────────────────────────────────────────────────
  Widget _buildColorSelector() {
    final colorMap = {
      'Black': Colors.black,
      'White': Colors.white,
      'Navy': const Color(0xFF0F1F4B),
      'Grey': Colors.grey,
      'Brown': const Color(0xFF7C4700),
    };

    return _sectionCard(
      title: 'Select Color',
      child: Wrap(
        spacing: 10,
        children: _colors.map((color) {
          final isSelected = _selectedColor == color;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedColor = color);
            },
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorMap[color],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? _kBlue : _kBorder,
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: _kBlue.withOpacity(0.3), blurRadius: 8)
                          ]
                        : [],
                  ),
                  child: isSelected
                      ? Icon(Icons.check_rounded,
                          color: color == 'White' ? _kBlue : Colors.white,
                          size: 16)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(color,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? _kBlue : _kInkMid)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Specifications grid ────────────────────────────────────────────────
  Widget _buildSpecs() {
    return _sectionCard(
      title: 'Product Details',
      child: Column(
        children: [
          ...List.generate((_specs.length / 2).ceil(), (row) {
            final left = _specs[row * 2];
            final right =
                row * 2 + 1 < _specs.length ? _specs[row * 2 + 1] : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: _specItem(left['label']!, left['value']!)),
                  if (right != null)
                    Expanded(
                        child: _specItem(right['label']!, right['value']!)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _specItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: _kInk)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: _kInkLight)),
      ],
    );
  }

  // ── Description ────────────────────────────────────────────────────────
  Widget _buildDescription() {
    return _sectionCard(
      title: 'Description',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _descExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              widget.product.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 13.5, color: _kInkMid, height: 1.6),
            ),
            secondChild: Text(
              widget.product.description,
              style:
                  const TextStyle(fontSize: 13.5, color: _kInkMid, height: 1.6),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _descExpanded ? 'Show less' : 'Show more',
                  style: const TextStyle(
                      color: _kBlue, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 3),
                Icon(
                  _descExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _kBlue,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky bottom CTA ──────────────────────────────────────────────────
  Widget _buildBottomCTA() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total',
                  style: TextStyle(fontSize: 11, color: _kInkMid)),
              Text(
                '₦${(widget.product.price * _selectedQty).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _kInk,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: _handleCartAction,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  gradient: _isInCart
                      ? null
                      : const LinearGradient(colors: [_kBlueDark, _kBlueMid]),
                  color: _isInCart ? const Color(0xFFFEF2F2) : null,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      _isInCart ? Border.all(color: Colors.red.shade200) : null,
                  boxShadow: _isInCart
                      ? []
                      : [
                          BoxShadow(
                            color: _kBlue.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isInCart
                          ? Icons.remove_shopping_cart_rounded
                          : Icons.add_shopping_cart_rounded,
                      color: _isInCart ? Colors.red : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isInCart ? 'Remove from Cart' : 'Add to Cart',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _isInCart ? Colors.red : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section card helper ────────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                    color: _kBlue, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  )),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
