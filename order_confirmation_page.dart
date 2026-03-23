import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iyadunni_shopmore/component.dart/check_out_model.dart';
import 'package:iyadunni_shopmore/order_detail_page.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════════════
class _C {
  // Blues
  static const b950 = Color(0xFF060F2E);
  static const b900 = Color(0xFF0D2260);
  static const b800 = Color(0xFF1240A8);
  static const b700 = Color(0xFF1A56DB);
  static const b600 = Color(0xFF2563EB);
  static const b500 = Color(0xFF3B82F6);
  static const b400 = Color(0xFF60A5FA);
  static const b200 = Color(0xFFBFDBFE);
  static const b100 = Color(0xFFDBEAFE);
  static const b50 = Color(0xFFEFF6FF);

  // Amber accent
  static const amber = Color(0xFFF59E0B);
  static const amberLt = Color(0xFFFEF3C7);

  // Success
  static const green = Color(0xFF10B981);
  static const greenLt = Color(0xFFD1FAE5);
  static const greenDk = Color(0xFF059669);

  // Neutrals
  static const white = Colors.white;
  static const ink = Color(0xFF0A1628);
  static const inkMid = Color(0xFF3D5170);
  static const inkSub = Color(0xFF8FA2C4);
  static const border = Color(0xFFD4E0F7);
  static const surf = Color(0xFFF4F8FF);

  // Shadows
  static List<BoxShadow> card = [
    BoxShadow(color: Color(0x141A56DB), blurRadius: 24, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0A1A56DB), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static List<BoxShadow> btn = [
    BoxShadow(
        color: Color(0x661A56DB),
        blurRadius: 20,
        offset: Offset(0, 7),
        spreadRadius: -3),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  ORDER CONFIRMATION PAGE
// ═══════════════════════════════════════════════════════════════════════════
class OrderConfirmationPage extends StatefulWidget {
  final Orders order;
  const OrderConfirmationPage({super.key, required this.order});

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage>
    with TickerProviderStateMixin {
  // ── Animation controllers ─────────────────────────────────────────────
  late final AnimationController _masterCtrl; // staggered content reveal
  late final AnimationController _pulseCtrl; // success-orb ring pulse
  late final AnimationController _orbitCtrl; // background ring rotation
  late final AnimationController _shimCtrl; // button shimmer

  // Staggered reveal
  late final Animation<double> _bgScale;
  late final Animation<double> _orbScale;
  late final Animation<double> _orbFade;
  late final Animation<Offset> _headSlide;
  late final Animation<double> _headFade;
  late final Animation<Offset> _card1Slide;
  late final Animation<double> _card1Fade;
  late final Animation<Offset> _card2Slide;
  late final Animation<double> _card2Fade;
  late final Animation<Offset> _card3Slide;
  late final Animation<double> _card3Fade;
  late final Animation<Offset> _btnSlide;
  late final Animation<double> _btnFade;

  // Pulse
  late final Animation<double> _pulse;
  late final Animation<double> _pulseOp;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    // ── Master staggered reveal (2.0 s) ──────────────────────────────────
    _masterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));

    _bgScale = Tween<double>(begin: 0.50, end: 1.0).animate(CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.00, 0.40, curve: Curves.easeOut)));

    _orbScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.08, 0.36, curve: Curves.elasticOut)));
    _orbFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.08, 0.24, curve: Curves.easeOut)));

    _headSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _masterCtrl,
            curve: const Interval(0.24, 0.50, curve: Curves.easeOut)));
    _headFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.24, 0.50, curve: Curves.easeOut)));

    _card1Slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _masterCtrl,
            curve: const Interval(0.38, 0.60, curve: Curves.easeOut)));
    _card1Fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.38, 0.60, curve: Curves.easeOut)));

    _card2Slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _masterCtrl,
            curve: const Interval(0.50, 0.70, curve: Curves.easeOut)));
    _card2Fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.50, 0.70, curve: Curves.easeOut)));

    _card3Slide = Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _masterCtrl,
            curve: const Interval(0.60, 0.80, curve: Curves.easeOut)));
    _card3Fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.60, 0.80, curve: Curves.easeOut)));

    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.20), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _masterCtrl,
            curve: const Interval(0.72, 0.92, curve: Curves.easeOut)));
    _btnFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.72, 0.92, curve: Curves.easeOut)));

    // ── Pulse ring (infinite) ─────────────────────────────────────────────
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1700))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.86, end: 1.16)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseOp = Tween<double>(begin: 0.24, end: 0.70)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ── Background orbit ──────────────────────────────────────────────────
    _orbitCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 28))
          ..repeat();

    // ── Shimmer ───────────────────────────────────────────────────────────
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();

    _masterCtrl.forward();
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    _shimCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get _deliveryMins {
    final diff =
        widget.order.checkoutInfo.deliveryTime.difference(DateTime.now());
    final m = diff.inMinutes;
    return m > 0 ? '~$m min' : 'Shortly';
  }

  bool get _isBankTransfer =>
      widget.order.checkoutInfo.paymentMethod == 'Bank Transfer';

  // ═════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── Background ─────────────────────────────────────────────
            _buildBackground(mq.size),

            // ── Scrollable content ─────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                          20, 0, 20, mq.padding.bottom + 120),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildSuccessOrb(),
                          const SizedBox(height: 22),
                          _buildHeading(),
                          const SizedBox(height: 26),
                          _buildOrderIdCard(),
                          const SizedBox(height: 14),
                          _buildDeliveryCard(),
                          const SizedBox(height: 14),
                          _buildItemsCard(),
                          if (_isBankTransfer) ...[
                            const SizedBox(height: 14),
                            _buildBankReminderCard(),
                          ],
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Sticky bottom bar ──────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _btnSlide,
                child: FadeTransition(
                  opacity: _btnFade,
                  child: _buildBottomBar(mq),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Background ─────────────────────────────────────────────────────────────
  Widget _buildBackground(Size s) {
    return Positioned.fill(
      child: Stack(children: [
        Container(color: Colors.white),

        // Top blue hero blob
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ScaleTransition(
            scale: _bgScale,
            alignment: Alignment.topCenter,
            child: Container(
              height: s.height * 0.46,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF060F2E),
                    Color(0xFF0D2260),
                    Color(0xFF1A56DB),
                    Color(0xFF3B82F6),
                  ],
                  stops: [0.0, 0.25, 0.62, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(54),
                  bottomRight: Radius.circular(54),
                ),
              ),
            ),
          ),
        ),

        // Orbiting rings
        Positioned(
          top: -s.height * 0.05,
          left: s.width * 0.5 - 175,
          child: AnimatedBuilder(
            animation: _orbitCtrl,
            builder: (_, __) => Transform.rotate(
              angle: _orbitCtrl.value * 2 * math.pi,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.038), width: 40),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: s.height * 0.02,
          left: s.width * 0.5 - 105,
          child: AnimatedBuilder(
            animation: _orbitCtrl,
            builder: (_, __) => Transform.rotate(
              angle: -_orbitCtrl.value * 2 * math.pi * 0.55,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.028), width: 20),
                ),
              ),
            ),
          ),
        ),

        // Corner glow accents
        Positioned(
            top: -50,
            left: -50,
            child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: _C.b600.withOpacity(0.15)))),
        Positioned(
            top: -30,
            right: -40,
            child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: _C.b400.withOpacity(0.10)))),

        // Bottom fade
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: s.height * 0.22,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, _C.b50.withOpacity(0.40)],
                ),
              ),
            )),
      ]),
    );
  }

  // ── Success orb ────────────────────────────────────────────────────────────
  Widget _buildSuccessOrb() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _masterCtrl]),
      builder: (_, __) => ScaleTransition(
        scale: _orbScale,
        child: FadeTransition(
          opacity: _orbFade,
          child: SizedBox(
            width: 168,
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ghost ring 1
                Opacity(
                  opacity: _pulseOp.value * 0.20,
                  child: Transform.scale(
                    scale: _pulse.value * 1.30,
                    child: Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.green, width: 1.5),
                      ),
                    ),
                  ),
                ),
                // Middle ring
                Opacity(
                  opacity: _pulseOp.value * 0.44,
                  child: Transform.scale(
                    scale: _pulse.value * 1.12,
                    child: Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.green, width: 2.5),
                      ),
                    ),
                  ),
                ),
                // Glow disc
                Container(
                  width: 106,
                  height: 106,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.green.withOpacity(0.10),
                  ),
                ),
                // Core circle
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _C.green.withOpacity(0.50),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: _C.green.withOpacity(0.18),
                        blurRadius: 60,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
                // Sparkles
                Positioned(
                    top: 18,
                    right: 22,
                    child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle))),
                Positioned(
                    bottom: 22,
                    left: 20,
                    child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: _C.b400, shape: BoxShape.circle))),
                Positioned(
                    top: 36,
                    left: 14,
                    child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                            color: Colors.white54, shape: BoxShape.circle))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Heading ────────────────────────────────────────────────────────────────
  Widget _buildHeading() {
    return SlideTransition(
      position: _headSlide,
      child: FadeTransition(
        opacity: _headFade,
        child: Column(
          children: [
            const Text(
              'Order Confirmed! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order has been received\nand is being processed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.76),
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 14),

            // Live status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.13),
                borderRadius: BorderRadius.circular(32),
                border:
                    Border.all(color: Colors.white.withOpacity(0.28), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _C.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: _C.amber, blurRadius: 6, spreadRadius: 1)
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Status: Pending',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Order ID card ──────────────────────────────────────────────────────────
  Widget _buildOrderIdCard() {
    return SlideTransition(
      position: _card1Slide,
      child: FadeTransition(
        opacity: _card1Fade,
        child: _SectionCard(
          child: Column(
            children: [
              // Order ID hero area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_C.b900, _C.b700, _C.b600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Order ID',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.order.orderId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Detail rows
              _DetailRow(
                icon: Icons.shopping_bag_rounded,
                iconColor: _C.b700,
                iconBg: _C.b50,
                label: 'Items',
                value:
                    '${widget.order.items.length} item${widget.order.items.length != 1 ? 's' : ''}',
              ),
              _DetailRow(
                icon: Icons.payments_rounded,
                iconColor: _C.green,
                iconBg: _C.greenLt,
                label: 'Total',
                value: '₦${widget.order.totalAmount.toStringAsFixed(0)}',
                valueStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _C.ink,
                  letterSpacing: -0.3,
                ),
              ),
              _DetailRow(
                icon: Icons.credit_card_rounded,
                iconColor: _C.amber,
                iconBg: _C.amberLt,
                label: 'Payment',
                value: widget.order.checkoutInfo.paymentMethod,
              ),
              _DetailRow(
                icon: Icons.access_time_rounded,
                iconColor: const Color(0xFF7C3AED),
                iconBg: const Color(0xFFF5F3FF),
                label: 'Delivery',
                value: _deliveryMins,
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delivery card ──────────────────────────────────────────────────────────
  Widget _buildDeliveryCard() {
    return SlideTransition(
      position: _card2Slide,
      child: FadeTransition(
        opacity: _card2Fade,
        child: _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _C.greenLt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.location_on_rounded,
                        color: _C.greenDk, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Delivery Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _C.ink,
                        letterSpacing: -0.2,
                      )),
                ],
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _C.surf,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _C.b100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.home_rounded,
                              color: _C.b700, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Delivery Address',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _C.inkSub,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  )),
                              const SizedBox(height: 3),
                              Text(
                                widget.order.checkoutInfo.deliveryAddress,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _C.ink,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(height: 1, color: _C.border),
                    const SizedBox(height: 10),
                    // Phone
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _C.greenLt,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.phone_rounded,
                              color: _C.greenDk, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Phone Number',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _C.inkSub,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                )),
                            const SizedBox(height: 2),
                            Text(
                              widget.order.checkoutInfo.phoneNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _C.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Notes (if present)
                    if (widget.order.checkoutInfo.notes?.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 10),
                      Container(height: 1, color: _C.border),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _C.amberLt,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.sticky_note_2_rounded,
                                color: _C.amber, size: 14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Notes',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _C.inkSub,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    )),
                                const SizedBox(height: 3),
                                Text(
                                  widget.order.checkoutInfo.notes!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _C.ink,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Items card ─────────────────────────────────────────────────────────────
  Widget _buildItemsCard() {
    return SlideTransition(
      position: _card3Slide,
      child: FadeTransition(
        opacity: _card3Fade,
        child: _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _C.b50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.receipt_long_rounded,
                        color: _C.b700, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Order Items',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _C.ink,
                        letterSpacing: -0.2,
                      )),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.b50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _C.b200, width: 1),
                    ),
                    child: Text(
                      '${widget.order.items.length} items',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _C.b700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Item rows
              ...widget.order.items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isLast = i == widget.order.items.length - 1;
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _C.surf,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _C.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          // Product image
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _C.b100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                item.product.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.fastfood_rounded,
                                  color: _C.b500,
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
                                      fontWeight: FontWeight.w700,
                                      color: _C.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _C.b100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('Qty: ${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _C.b700,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₦${(item.product.price * item.quantity).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _C.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) const SizedBox(height: 8),
                  ],
                );
              }),

              const SizedBox(height: 14),

              // Total summary row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_C.b900, _C.b700],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(
                      '₦${widget.order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bank transfer reminder ─────────────────────────────────────────────────
  Widget _buildBankReminderCard() {
    return SlideTransition(
      position: _btnSlide,
      child: FadeTransition(
        opacity: _btnFade,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.amberLt,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.amber.withOpacity(0.40), width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _C.amber.withOpacity(0.20),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_rounded, color: _C.amber, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Remember to send your payment proof via WhatsApp to confirm your order.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom action bar ──────────────────────────────────────────────────────
  Widget _buildBottomBar(MediaQueryData mq) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, mq.padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _C.b700.withOpacity(0.09),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          // View Order — outlined
          Expanded(
            child: _PressBtn(
              onTap: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      OrderDetailPage(order: widget.order),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration: const Duration(milliseconds: 350),
                ),
              ),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.b200, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: _C.b700.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_rounded, color: _C.b700, size: 18),
                    const SizedBox(width: 7),
                    Text('View Order',
                        style: TextStyle(
                          color: _C.b700,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Continue Shopping — filled gradient with shimmer
          Expanded(
            flex: 2,
            child: _PressBtn(
              onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: AnimatedBuilder(
                animation: _shimCtrl,
                builder: (_, __) => Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_C.b900, _C.b700, _C.b600],
                      stops: [0.0, 0.50, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _C.btn,
                  ),
                  child: Stack(
                    children: [
                      // Shimmer sweep
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FractionallySizedBox(
                            widthFactor: 0.36,
                            alignment:
                                Alignment((_shimCtrl.value * 3.4) - 1.7, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.10),
                                  Colors.white.withOpacity(0),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.storefront_rounded,
                                  color: Colors.white, size: 15),
                            ),
                            const SizedBox(width: 8),
                            const Text('Keep Shopping',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                )),
                          ],
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
}

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION CARD WRAPPER
// ═══════════════════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.border, width: 1),
        boxShadow: _C.card,
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DETAIL ROW
// ═══════════════════════════════════════════════════════════════════════════
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.valueStyle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _C.inkSub,
                    fontWeight: FontWeight.w500,
                  )),
              const Spacer(),
              Text(value,
                  style: valueStyle ??
                      const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.ink,
                      )),
            ],
          ),
        ),
        if (!isLast) Container(height: 1, color: _C.border),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PRESSABLE BUTTON WRAPPER
// ═══════════════════════════════════════════════════════════════════════════
class _PressBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressBtn({required this.child, required this.onTap});

  @override
  State<_PressBtn> createState() => _PressBtnState();
}

class _PressBtnState extends State<_PressBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _down = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: widget.child,
      ),
    );
  }
}
