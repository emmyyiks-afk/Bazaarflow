import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iyadunni_shopmore/service/firestore_service.dart';
import 'package:iyadunni_shopmore/component.dart/cart_items.dart';
import 'package:iyadunni_shopmore/component.dart/check_out_model.dart';
import 'package:iyadunni_shopmore/order_confirmation_page.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const primary = Color(0xFF1A56DB);
  static const primaryDark = Color(0xFF1240A8);
  static const primaryLight = Color(0xFFEEF3FD);
  static const primaryMid = Color(0xFF3B82F6);
  static const accent = Color(0xFFF59E0B);
  static const accentLight = Color(0xFFFEF3C7);
  static const success = Color(0xFF059669);
  static const successLight = Color(0xFFD1FAE5);
  static const error = Color(0xFFDC2626);
  static const errorLight = Color(0xFFFEF2F2);
  static const surface = Color(0xFFF8FAFF);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const divider = Color(0xFFF1F5F9);
}

// ─── Paystack Keys ────────────────────────────────────────────────────────────
class _Paystack {
  // ⚠️ Replace with your actual keys
  static const String publicKey = 'pk_test_355b447cbc5b29a870b2bba753f4f9028018f268';
  static const String secretKey = 'sk_test_277e8a9dbd30a1ee6a3f2d054a7d85deb3d6f317';
  static const String baseUrl = 'https://api.paystack.co';
}

// ─── Paystack Service ─────────────────────────────────────────────────────────
class _PaystackService {
  /// Initializes transaction → returns authorization URL
  static Future<Map<String, dynamic>> initializeTransaction({
    required String email,
    required int amountInKobo,
    required String reference,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await http.post(
      Uri.parse('${_Paystack.baseUrl}/transaction/initialize'),
      headers: {
        'Authorization': 'Bearer ${_Paystack.secretKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'amount': amountInKobo,
        'reference': reference,
        'currency': 'NGN',
        if (metadata != null) 'metadata': metadata,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      return {
        'authorization_url': data['data']['authorization_url'],
        'reference': data['data']['reference'],
        'access_code': data['data']['access_code'],
      };
    }
    throw Exception('Paystack init failed: ${data['message']}');
  }

  /// Verifies transaction by reference
  static Future<Map<String, dynamic>> verifyTransaction(
      String reference) async {
    final response = await http.get(
      Uri.parse('${_Paystack.baseUrl}/transaction/verify/$reference'),
      headers: {
        'Authorization': 'Bearer ${_Paystack.secretKey}',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception('Paystack verify failed: ${data['message']}');
  }

  /// Generates a unique reference per order
  static String generateReference(String orderId) {
    return 'BZF_${orderId}_${DateTime.now().millisecondsSinceEpoch}';
  }
}

// ─── Paystack WebView Page ─────────────────────────────────────────────────────
class _PaystackWebViewPage extends StatefulWidget {
  final String authorizationUrl;
  final String reference;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const _PaystackWebViewPage({
    required this.authorizationUrl,
    required this.reference,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<_PaystackWebViewPage> createState() => _PaystackWebViewPageState();
}

class _PaystackWebViewPageState extends State<_PaystackWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _callbackHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            _handleUrlChange(url);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _handleUrlChange(url);
          },
          onNavigationRequest: (request) {
            _handleUrlChange(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  void _handleUrlChange(String url) {
    if (_callbackHandled) return;

    // Paystack redirects to this pattern on success/cancel
    if (url.contains('paystack') &&
        (url.contains('callback') ||
            url.contains('trxref') ||
            url.contains('reference'))) {
      if (url.contains('trxref') || url.contains('reference')) {
        _callbackHandled = true;
        widget.onSuccess();
      }
    }

    // User closed / went back
    if (url.contains('cancel') || url.contains('close')) {
      _callbackHandled = true;
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _C.primaryDark,
        foregroundColor: Colors.white,
        title: const Text(
          'Secure Payment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            widget.onCancel();
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text('SSL Secured',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _C.primary),
                    SizedBox(height: 16),
                    Text('Loading secure payment...',
                        style: TextStyle(
                            color: _C.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── CheckoutPage ─────────────────────────────────────────────────────────────
class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;
  final User? currentUser;
  final Function(Orders) onOrderPlaced;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    required this.onOrderPlaced,
    required this.currentUser,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _deliverySectionKey = GlobalKey();
  final GlobalKey _paymentSectionKey = GlobalKey();
  final GlobalKey _termsSectionKey = GlobalKey();

  // Payment methods — bank transfer removed, Paystack added
  String _selectedPaymentMethod = 'Cash on Delivery';
  DateTime _selectedDeliveryTime =
      DateTime.now().add(const Duration(minutes: 45));
  bool _isPlacingOrder = false;
  bool _agreedToTerms = false;
  bool _formSubmitAttempted = false;

  // Paystack state
  bool _paystackPaymentVerified = false;
  String? _paystackReference;

  int _currentStep = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const double _deliveryFee = 700.0;
  double get _grandTotal => widget.totalAmount + _deliveryFee;

  bool get _addressOk => _addressController.text.trim().isNotEmpty;
  bool get _phoneOk =>
      _phoneController.text.trim().isNotEmpty &&
      _phoneController.text.trim().length >= 10;

  bool get _canPlaceOrder {
    if (!_addressOk) return false;
    if (!_phoneOk) return false;
    if (!_agreedToTerms) return false;
    if (_selectedPaymentMethod == 'Paystack' && !_paystackPaymentVerified) {
      return false;
    }
    return true;
  }

  String? get _firstBlockReason {
    if (!_addressOk) return 'Please enter your delivery address.';
    if (!_phoneOk) return 'Please enter a valid phone number (min 10 digits).';
    if (!_agreedToTerms) return 'Please agree to the Terms & Conditions.';
    if (_selectedPaymentMethod == 'Paystack' && !_paystackPaymentVerified) {
      return 'Please complete your Paystack payment before placing the order.';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _addressController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_C.primaryDark, _C.primary, _C.primaryMid],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildProgressSteps(),
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    child: Container(
                      color: _C.surface,
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _formSubmitAttempted
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        child: ListView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 20, 16, 130),
                          children: [
                            _buildOrderSummaryCard(),
                            const SizedBox(height: 16),
                            KeyedSubtree(
                              key: _deliverySectionKey,
                              child: _buildDeliveryCard(),
                            ),
                            const SizedBox(height: 16),
                            KeyedSubtree(
                              key: _paymentSectionKey,
                              child: _buildPaymentCard(),
                            ),
                            const SizedBox(height: 16),
                            _buildDeliveryTimeCard(),
                            const SizedBox(height: 16),
                            _buildNotesCard(),
                            const SizedBox(height: 16),
                            KeyedSubtree(
                              key: _termsSectionKey,
                              child: _buildTermsRow(),
                            ),
                            if (_formSubmitAttempted && !_canPlaceOrder) ...[
                              const SizedBox(height: 12),
                              _buildErrorBanner(_firstBlockReason ?? ''),
                            ],
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomBar(),
          ),
          if (_isPlacingOrder) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Checkout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    )),
                Text('Review & confirm your order',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _C.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_bag_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${widget.cartItems.length} item${widget.cartItems.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Progress Steps ───────────────────────────────────────────────────────
  Widget _buildProgressSteps() {
    final steps = ['Summary', 'Delivery', 'Payment', 'Confirm'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < _currentStep
                    ? _C.accent
                    : Colors.white.withOpacity(0.25),
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < _currentStep;
          final isActive = stepIndex == _currentStep;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? _C.accent
                      : isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(color: _C.accent, width: 2)
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 14)
                      : Text('${stepIndex + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                isActive ? _C.primary : Colors.white70,
                          )),
                ),
              ),
              const SizedBox(height: 4),
              Text(steps[stepIndex],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.normal,
                    color: isActive || isDone
                        ? Colors.white
                        : Colors.white54,
                  )),
            ],
          );
        }),
      ),
    );
  }

  // ─── Order Summary ─────────────────────────────────────────────────────────
  Widget _buildOrderSummaryCard() {
    return _SectionCard(
      icon: Icons.receipt_long_rounded,
      iconColor: _C.primary,
      iconBg: _C.primaryLight,
      title: 'Order Summary',
      badge: '${widget.cartItems.length} items',
      badgeColor: _C.primaryLight,
      badgeTextColor: _C.primary,
      child: Column(
        children: [
          ...widget.cartItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _C.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          item.product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.fastfood_rounded,
                            color: _C.primary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _C.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _C.divider,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Qty: ${item.quantity}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _C.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₦${(item.product.price * item.quantity).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
          Container(height: 1, color: _C.divider),
          const SizedBox(height: 10),
          _PriceRow(
              label: 'Subtotal',
              amount: widget.totalAmount,
              isAccent: false),
          const SizedBox(height: 6),
          _PriceRow(
            label: 'Delivery Fee',
            amount: _deliveryFee,
            isAccent: false,
            prefix: Icons.delivery_dining_rounded,
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: _C.divider),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_C.primaryDark, _C.primary]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text('₦${_grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Delivery Card ─────────────────────────────────────────────────────────
  Widget _buildDeliveryCard() {
    final showAddressError = _formSubmitAttempted && !_addressOk;
    final showPhoneError = _formSubmitAttempted && !_phoneOk;

    return _SectionCard(
      icon: Icons.location_on_rounded,
      iconColor: _C.success,
      iconBg: _C.successLight,
      title: 'Delivery Details',
      badge: (_formSubmitAttempted && (!_addressOk || !_phoneOk))
          ? '⚠ Fill required fields'
          : null,
      badgeColor: _C.errorLight,
      badgeTextColor: _C.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            style: const TextStyle(
                fontSize: 14, color: _C.textPrimary, height: 1.4),
            decoration: InputDecoration(
              hintText: 'Enter your full delivery address *',
              hintStyle:
                  const TextStyle(color: _C.textMuted, fontSize: 13),
              prefixIcon: Icon(Icons.home_rounded,
                  color: showAddressError ? _C.error : _C.primary,
                  size: 20),
              filled: true,
              fillColor:
                  showAddressError ? _C.errorLight : _C.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: showAddressError ? _C.error : _C.border,
                  width: showAddressError ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: showAddressError ? _C.error : _C.primary,
                  width: 1.5,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _C.border),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _C.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _C.error, width: 1.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Delivery address is required';
              }
              return null;
            },
          ),
          if (showAddressError)
            _inlineError('Delivery address is required'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            style: const TextStyle(
                fontSize: 14, color: _C.textPrimary, height: 1.4),
            decoration: InputDecoration(
              hintText: 'Phone number * (min 10 digits)',
              hintStyle:
                  const TextStyle(color: _C.textMuted, fontSize: 13),
              prefixIcon: Icon(Icons.phone_rounded,
                  color: showPhoneError ? _C.error : _C.primary,
                  size: 20),
              filled: true,
              fillColor: showPhoneError ? _C.errorLight : _C.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: showPhoneError ? _C.error : _C.border,
                  width: showPhoneError ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: showPhoneError ? _C.error : _C.primary,
                  width: 1.5,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _C.border),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _C.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _C.error, width: 1.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Phone number is required';
              }
              if (v.trim().length < 10) {
                return 'Enter a valid phone number (min 10 digits)';
              }
              return null;
            },
          ),
          if (showPhoneError)
            _inlineError(
                'Valid phone number is required (min 10 digits)'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded,
                    color: _C.accent, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Our rider will call you on this number when nearby.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Payment Card ──────────────────────────────────────────────────────────
  Widget _buildPaymentCard() {
    final showPaystackError = _formSubmitAttempted &&
        _selectedPaymentMethod == 'Paystack' &&
        !_paystackPaymentVerified;

    return _SectionCard(
      icon: Icons.payments_rounded,
      iconColor: _C.accent,
      iconBg: _C.accentLight,
      title: 'Payment Method',
      badge: showPaystackError ? '⚠ Complete payment' : null,
      badgeColor: _C.errorLight,
      badgeTextColor: _C.error,
      child: Column(
        children: [
          // ── Cash on Delivery ────────────────────────────────────────────
          _PaymentOptionTile(
            icon: Icons.money_rounded,
            iconColor: _C.success,
            title: 'Cash on Delivery',
            subtitle: 'Pay when you receive your order',
            isSelected: _selectedPaymentMethod == 'Cash on Delivery',
            onTap: () => setState(() {
              _selectedPaymentMethod = 'Cash on Delivery';
              _paystackPaymentVerified = false;
              _paystackReference = null;
            }),
          ),
          const SizedBox(height: 8),

          // ── Paystack ────────────────────────────────────────────────────
          _PaymentOptionTile(
            icon: Icons.credit_card_rounded,
            iconColor: _C.primary,
            title: 'Pay with Paystack',
            subtitle: 'Card, Bank Transfer, USSD & more',
            isSelected: _selectedPaymentMethod == 'Paystack',
            onTap: () => setState(() {
              _selectedPaymentMethod = 'Paystack';
              _paystackPaymentVerified = false;
              _paystackReference = null;
            }),
          ),

          // ── Paystack expanded section ────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _selectedPaymentMethod == 'Paystack'
                ? _buildPaystackSection(showPaystackError)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaystackSection(bool showError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(height: 1, color: _C.divider),
        const SizedBox(height: 16),

        // ── Accepted methods chips ──────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MethodChip(icon: Icons.credit_card_rounded, label: 'Card'),
            _MethodChip(
                icon: Icons.account_balance_rounded, label: 'Bank Transfer'),
            _MethodChip(icon: Icons.phone_android_rounded, label: 'USSD'),
            _MethodChip(
                icon: Icons.mobile_friendly_rounded, label: 'Mobile Money'),
          ],
        ),
        const SizedBox(height: 16),

        // ── Status / Pay button ─────────────────────────────────────────
        if (_paystackPaymentVerified) ...[
          // Payment verified ✓
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.successLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.success.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _C.success,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Confirmed ✓',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _C.success,
                            fontSize: 14,
                          )),
                      if (_paystackReference != null)
                        Text('Ref: $_paystackReference',
                            style: const TextStyle(
                                fontSize: 11,
                                color: _C.textSecondary)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _paystackPaymentVerified = false;
                    _paystackReference = null;
                  }),
                  child: const Text('Change',
                      style: TextStyle(
                          fontSize: 12, color: _C.textSecondary)),
                ),
              ],
            ),
          ),
        ] else ...[
          // Pay Now button
          GestureDetector(
            onTap: _isPlacingOrder ? null : _launchPaystack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF011B33), Color(0xFF00C3F7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: showError
                    ? Border.all(color: _C.error, width: 1.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C3F7).withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    'Pay ₦${_grandTotal.toStringAsFixed(0)} Securely',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showError)
            _inlineError(
                'Complete Paystack payment before placing the order'),
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified_user_rounded,
                    color: _C.textMuted, size: 12),
                SizedBox(width: 4),
                Text('Secured by Paystack — 256-bit SSL',
                    style:
                        TextStyle(fontSize: 11, color: _C.textMuted)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Delivery Time ─────────────────────────────────────────────────────────
  Widget _buildDeliveryTimeCard() {
    final minsLeft =
        _selectedDeliveryTime.difference(DateTime.now()).inMinutes;
    final hour = _selectedDeliveryTime.hour;
    final min =
        _selectedDeliveryTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour =
        hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return _SectionCard(
      icon: Icons.access_time_rounded,
      iconColor: const Color(0xFF7C3AED),
      iconBg: const Color(0xFFF5F3FF),
      title: 'Delivery Time',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              Text('$displayHour:$min $period',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  )),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Arriving in ~$minsLeft minutes',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: const [
            Text('30 min',
                style:
                    TextStyle(fontSize: 11, color: _C.textSecondary)),
            Spacer(),
            Text('120 min',
                style:
                    TextStyle(fontSize: 11, color: _C.textSecondary)),
          ]),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF7C3AED),
              inactiveTrackColor: const Color(0xFFEDE9FE),
              thumbColor: const Color(0xFF7C3AED),
              overlayColor:
                  const Color(0xFF7C3AED).withOpacity(0.15),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: minsLeft.toDouble().clamp(30, 120),
              min: 30,
              max: 120,
              divisions: 9,
              label: '$minsLeft min',
              onChanged: (value) => setState(() {
                _selectedDeliveryTime = DateTime.now()
                    .add(Duration(minutes: value.toInt()));
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Notes ─────────────────────────────────────────────────────────────────
  Widget _buildNotesCard() {
    return _SectionCard(
      icon: Icons.sticky_note_2_rounded,
      iconColor: const Color(0xFF0891B2),
      iconBg: const Color(0xFFECFEFF),
      title: 'Order Notes',
      badge: 'Optional',
      badgeColor: const Color(0xFFECFEFF),
      badgeTextColor: const Color(0xFF0891B2),
      child: _StyledTextField(
        controller: _notesController,
        hintText:
            'Any special instructions? (e.g. gate code, landmark...)',
        prefixIcon: Icons.edit_note_rounded,
        maxLines: 3,
      ),
    );
  }

  // ─── Terms ──────────────────────────────────────────────────────────────────
  Widget _buildTermsRow() {
    final showTermsError = _formSubmitAttempted && !_agreedToTerms;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _agreedToTerms = !_agreedToTerms),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: _agreedToTerms ? _C.primary : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: showTermsError
                        ? _C.error
                        : _agreedToTerms
                            ? _C.primary
                            : _C.border,
                    width: 2,
                  ),
                ),
                child: _agreedToTerms
                    ? const Icon(Icons.check,
                        color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(
                        fontSize: 12, color: _C.textSecondary),
                    children: [
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                          color: _C.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(
                          text:
                              ' and confirm that all information is accurate.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showTermsError)
          _inlineError('You must agree to the Terms & Conditions'),
      ],
    );
  }

  // ─── Bottom Bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final blocked = !_canPlaceOrder;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Total to Pay',
                  style: TextStyle(
                      fontSize: 12, color: _C.textSecondary)),
              Text('₦${_grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _C.textPrimary,
                    letterSpacing: -0.5,
                  )),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ScaleTransition(
              scale: blocked
                  ? const AlwaysStoppedAnimation(1.0)
                  : _pulseAnimation,
              child: GestureDetector(
                onTap: _isPlacingOrder ? null : _handlePlaceOrderTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: blocked
                        ? const LinearGradient(colors: [
                            Color(0xFFCBD5E1),
                            Color(0xFFCBD5E1)
                          ])
                        : const LinearGradient(
                            colors: [_C.success, Color(0xFF047857)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: blocked
                        ? []
                        : [
                            BoxShadow(
                              color: _C.success.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: _isPlacingOrder
                      ? const Center(
                          child: SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              blocked
                                  ? Icons.lock_rounded
                                  : Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              blocked
                                  ? 'COMPLETE FORM'
                                  : 'PLACE ORDER',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading Overlay ───────────────────────────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 50, height: 50,
                child: CircularProgressIndicator(
                    color: _C.primary, strokeWidth: 3),
              ),
              SizedBox(height: 16),
              Text('Placing your order...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary,
                  )),
              SizedBox(height: 4),
              Text('Please wait a moment',
                  style:
                      TextStyle(fontSize: 12, color: _C.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Error Banner ──────────────────────────────────────────────────────────
  Widget _buildErrorBanner(String message) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.errorLight,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: _C.error.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: _C.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                  fontSize: 13,
                  color: _C.error,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                )),
          ),
        ],
      ),
    );
  }

  Widget _inlineError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: _C.error, size: 13),
          const SizedBox(width: 4),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                  fontSize: 11,
                  color: _C.error,
                  fontWeight: FontWeight.w500,
                )),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Opens Paystack WebView → on success verifies → updates state
  Future<void> _launchPaystack() async {
    if (widget.currentUser == null) {
      _showErrorSnack('Please sign in to pay.');
      return;
    }
    if (!_addressOk || !_phoneOk) {
      _showErrorSnack(
          'Please fill in your delivery address and phone number first.');
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final orderId =
          'ORD${DateTime.now().millisecondsSinceEpoch}';
      final reference =
          _PaystackService.generateReference(orderId);
      final email =
          widget.currentUser!.email ?? 'customer@bazaarflow.ng';
      final amountKobo = (_grandTotal * 100).toInt();

      final initResult =
          await _PaystackService.initializeTransaction(
        email: email,
        amountInKobo: amountKobo,
        reference: reference,
        metadata: {
          'order_id': orderId,
          'customer_name':
              widget.currentUser!.displayName ?? 'Customer',
          'delivery_address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
      );

      setState(() => _isPlacingOrder = false);

      final authUrl =
          initResult['authorization_url'] as String;
      final txRef = initResult['reference'] as String;

      if (!mounted) return;

      // ── Open WebView ──────────────────────────────────────────────────
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PaystackWebViewPage(
            authorizationUrl: authUrl,
            reference: txRef,
            onSuccess: () async {
              Navigator.pop(context); // close WebView
              await _verifyAndConfirmPayment(txRef);
            },
            onCancel: () {
              Navigator.pop(context);
              _showErrorSnack('Payment cancelled. Try again when ready.');
            },
          ),
        ),
      );
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      _showErrorSnack('Could not connect to Paystack: $e');
    }
  }

  Future<void> _verifyAndConfirmPayment(String reference) async {
    setState(() => _isPlacingOrder = true);

    try {
      final result =
          await _PaystackService.verifyTransaction(reference);
      final status = result['status'] as String? ?? '';

      if (status == 'success') {
        setState(() {
          _paystackPaymentVerified = true;
          _paystackReference = reference;
          _isPlacingOrder = false;
        });
        HapticFeedback.heavyImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Payment successful! Now place your order.'),
            ]),
            backgroundColor: _C.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            duration: const Duration(seconds: 3),
          ));
        }
      } else {
        setState(() => _isPlacingOrder = false);
        _showErrorSnack(
            'Payment not confirmed (status: $status). Please try again.');
      }
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      _showErrorSnack('Could not verify payment: $e');
    }
  }

  void _handlePlaceOrderTap() {
    setState(() => _formSubmitAttempted = true);
    final formValid =
        _formKey.currentState?.validate() ?? false;

    if (!formValid) {
      _scrollToSection(_deliverySectionKey);
      _showErrorSnack('Please fill in all required fields.');
      return;
    }
    if (!_agreedToTerms) {
      _scrollToSection(_termsSectionKey);
      _showErrorSnack('Please agree to the Terms & Conditions.');
      return;
    }
    if (_selectedPaymentMethod == 'Paystack' &&
        !_paystackPaymentVerified) {
      _scrollToSection(_paymentSectionKey);
      _showErrorSnack(
          'Please complete your Paystack payment first.');
      return;
    }
    _placeOrder();
  }

  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.0);
  }

  void _showErrorSnack(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: _C.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Place order ─────────────────────────────────────────────────────────────
  Future<void> _placeOrder() async {
    if (widget.currentUser == null) {
      _showErrorSnack('Please sign in to place an order.');
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final cartSnapshot = List<CartItem>.from(widget.cartItems);

      final checkoutInfo = CheckoutInfo(
        deliveryAddress: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        deliveryTime: _selectedDeliveryTime,
      );

      final sellerIds = cartSnapshot
          .expand(
              (item) => item.product.sellerIds ?? <String>[])
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final order = Orders(
        orderId: 'ORD${DateTime.now().millisecondsSinceEpoch}',
        items: cartSnapshot,
        totalAmount: _grandTotal,
        orderDate: DateTime.now(),
        status: _selectedPaymentMethod == 'Paystack'
            ? 'Paid'     // already verified
            : 'Pending', // cash on delivery
        checkoutInfo: checkoutInfo,
        userId: widget.currentUser!.uid,
        userEmail: widget.currentUser!.email,
        userName:
            widget.currentUser!.displayName ?? 'Customer',
        sellerIds: sellerIds,
        // pass reference so you can look it up in Firestore later
        paystackReference: _paystackReference,
      );

      await _firestoreService.saveOrder(order);
      widget.onOrderPlaced(order);

      HapticFeedback.heavyImpact();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  OrderConfirmationPage(order: order)),
        );
      }
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      if (mounted) _showErrorSnack('Failed to place order: $e');
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _MethodChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MethodChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _C.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _C.primary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _C.primary)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.child,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  )),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(badge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeTextColor,
                      )),
                ),
              ],
            ]),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      autocorrect: false,
      style: const TextStyle(
          fontSize: 14, color: _C.textPrimary, height: 1.4),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
            const TextStyle(color: _C.textMuted, fontSize: 13),
        prefixIcon:
            Icon(prefixIcon, color: _C.primary, size: 20),
        filled: true,
        fillColor: _C.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: _C.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _C.primaryLight : _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _C.primary : _C.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? _C.primary
                          : _C.textPrimary,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: _C.textSecondary)),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: isSelected ? _C.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _C.primary : _C.border,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check,
                    color: Colors.white, size: 13)
                : null,
          ),
        ]),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isAccent;
  final IconData? prefix;

  const _PriceRow({
    required this.label,
    required this.amount,
    required this.isAccent,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          if (prefix != null) ...[
            Icon(prefix, size: 14, color: _C.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: _C.textSecondary)),
        ]),
        Text('₦${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isAccent ? _C.primary : _C.textSecondary,
            )),
      ],
    );
  }
}