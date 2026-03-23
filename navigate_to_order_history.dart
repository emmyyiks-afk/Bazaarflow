import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iyadunni_shopmore/component.dart/check_out_model.dart';
import 'package:iyadunni_shopmore/component.dart/cart_items.dart';
import 'package:iyadunni_shopmore/order_detail_page.dart';

// ═══════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════
class _C {
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

  static const green = Color(0xFF10B981);
  static const greenLt = Color(0xFFD1FAE5);
  static const greenDk = Color(0xFF059669);
  static const amber = Color(0xFFF59E0B);
  static const amberLt = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const redLt = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purpleLt = Color(0xFFEDE9FE);

  static const ink = Color(0xFF0A1628);
  static const inkMid = Color(0xFF3D5170);
  static const inkSub = Color(0xFF8FA2C4);
  static const border = Color(0xFFD4E0F7);
  static const surf = Color(0xFFF4F8FF);

  static List<BoxShadow> card = [
    BoxShadow(color: Color(0x121A56DB), blurRadius: 20, offset: Offset(0, 5)),
    BoxShadow(color: Color(0x091A56DB), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static List<BoxShadow> btn = [
    BoxShadow(
        color: Color(0x5C1A56DB),
        blurRadius: 18,
        offset: Offset(0, 6),
        spreadRadius: -3),
  ];

  static Color statusColor(String s) {
    switch (s) {
      case 'pending':
        return amber;
      case 'confirmed':
      case 'processing':
        return b600;
      case 'preparing':
        return purple;
      case 'on the way':
        return b800;
      case 'delivered':
        return green;
      case 'cancelled':
        return red;
      default:
        return inkSub;
    }
  }

  static Color statusBg(String s) {
    switch (s) {
      case 'pending':
        return amberLt;
      case 'confirmed':
      case 'processing':
        return b100;
      case 'preparing':
        return purpleLt;
      case 'on the way':
        return b50;
      case 'delivered':
        return greenLt;
      case 'cancelled':
        return redLt;
      default:
        return surf;
    }
  }

  static IconData statusIcon(String s) {
    switch (s) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'confirmed':
      case 'processing':
        return Icons.sync_rounded;
      case 'preparing':
        return Icons.kitchen_rounded;
      case 'on the way':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  ORDER HISTORY PAGE
// ═══════════════════════════════════════════════════════════════
class OrderHistoryPage extends StatefulWidget {
  final List<Orders> orders;
  final Function(Orders)? onReorder;
  final Stream<List<Orders>>? ordersStream;

  const OrderHistoryPage({
    super.key,
    required this.orders,
    this.onReorder,
    this.ordersStream,
  });

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with TickerProviderStateMixin {
  bool _hasError = false;
  String _errorMessage = '';
  List<Orders> _cachedOrders = [];
  String _filterStatus = 'all';

  late final AnimationController _headerCtrl;
  late final AnimationController _orbitCtrl;
  late final AnimationController _shimCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _bgScale;

  static const _statuses = [
    'all',
    'pending',
    'confirmed',
    'on the way',
    'delivered',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _cachedOrders = List.from(widget.orders);

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850));
    _bgScale = Tween<double>(begin: 0.55, end: 1.0).animate(CurvedAnimation(
        parent: _headerCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut)));
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _headerCtrl,
        curve: const Interval(0.20, 0.80, curve: Curves.easeOut)));
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.30), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _headerCtrl,
                curve: const Interval(0.20, 0.80, curve: Curves.easeOut)));

    _orbitCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 28))
          ..repeat();
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();

    _headerCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _orbitCtrl.dispose();
    _shimCtrl.dispose();
    super.dispose();
  }

  List<Orders> _filtered(List<Orders> all) {
    if (_filterStatus == 'all') return all;
    return all
        .where((o) => (o.status?.toLowerCase() ?? '') == _filterStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            _Background(
                bgScale: _bgScale, orbitCtrl: _orbitCtrl, screenSize: mq.size),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildFilterPills(),
                  Expanded(
                    child: _hasError
                        ? _buildErrorState()
                        : widget.ordersStream != null
                            ? _buildStreamContent()
                            : _buildMainContent(_cachedOrders),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _headerFade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Row(
            children: [
              _PressBtn(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.28), width: 1),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Orders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      '${_cachedOrders.length} order${_cachedOrders.length != 1 ? 's' : ''} total',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.66),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _PressBtn(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                  });
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.28), width: 1),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter pills ───────────────────────────────────────────────
  Widget _buildFilterPills() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statuses.length,
        itemBuilder: (_, i) {
          final s = _statuses[i];
          final active = s == _filterStatus;
          final label =
              s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _PressBtn(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _filterStatus = s);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          colors: [_C.b900, _C.b700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)
                      : null,
                  color: active ? null : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: active ? Colors.transparent : _C.border,
                    width: 1.2,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: _C.b700.withOpacity(0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                              spreadRadius: -2)
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (s != 'all') ...[
                      Icon(_C.statusIcon(s),
                          size: 12,
                          color: active ? Colors.white : _C.statusColor(s)),
                      const SizedBox(width: 5),
                    ],
                    Text(label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : _C.inkMid,
                        )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Stream ─────────────────────────────────────────────────────
  Widget _buildStreamContent() {
    return StreamBuilder<List<Orders>>(
      stream: widget.ordersStream,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          if (_cachedOrders.isNotEmpty) {
            return Column(children: [
              LinearProgressIndicator(
                backgroundColor: _C.b100,
                valueColor: const AlwaysStoppedAnimation(_C.b600),
                minHeight: 2,
              ),
              Expanded(child: _buildMainContent(_cachedOrders)),
            ]);
          }
          return _buildLoadingState();
        }
        if (snap.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                _hasError = true;
                _errorMessage = snap.error.toString();
              }));
          return _buildMainContent(_cachedOrders);
        }
        if (!snap.hasData || snap.data == null) return _buildEmptyState();
        _cachedOrders = snap.data!;
        return _buildMainContent(snap.data!);
      },
    );
  }

  // ── Main list ──────────────────────────────────────────────────
  Widget _buildMainContent(List<Orders> all) {
    final filtered = _filtered(all);
    if (filtered.isEmpty) return _buildEmptyState();
    return RefreshIndicator(
      color: _C.b700,
      backgroundColor: Colors.white,
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, MediaQuery.of(context).padding.bottom + 24),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _OrderCard(
          key: ValueKey(filtered[i].orderId),
          order: filtered[i],
          index: i,
          onReorder: widget.onReorder,
          shimCtrl: _shimCtrl,
          onViewDetails: (o) => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => OrderDetailPage(order: o),
                transitionsBuilder: (_, a, __, child) =>
                    FadeTransition(opacity: a, child: child),
                transitionDuration: const Duration(milliseconds: 350),
              )),
          onReorderTap: (o) {
            widget.onReorder!(o);
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                    '${o.items.length} item${o.items.length != 1 ? 's' : ''} added to cart!'),
              ]),
              backgroundColor: _C.b700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ));
          },
        ),
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _C.b50,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: _C.b700.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: const AlwaysStoppedAnimation(_C.b700),
                backgroundColor: _C.b200),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Loading your orders…',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: _C.inkMid)),
        const SizedBox(height: 6),
        const Text('This won\'t take long',
            style: TextStyle(fontSize: 12, color: _C.inkSub)),
        const SizedBox(height: 24),
        _PressBtn(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
                color: _C.b50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.b200, width: 1)),
            child: const Text('Go Back',
                style: TextStyle(
                    color: _C.b700, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  // ── Error ──────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 88,
              height: 88,
              decoration:
                  const BoxDecoration(color: _C.redLt, shape: BoxShape.circle),
              child:
                  const Icon(Icons.wifi_off_rounded, color: _C.red, size: 40)),
          const SizedBox(height: 20),
          const Text('Unable to Load Orders',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _C.ink,
                  letterSpacing: -0.4)),
          const SizedBox(height: 8),
          Text(
            _errorMessage.isNotEmpty
                ? _errorMessage
                : 'Check your internet connection and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _C.inkSub, height: 1.5),
          ),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _PressBtn(
              onTap: () => setState(() {
                _hasError = false;
                _errorMessage = '';
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [_C.b900, _C.b700, _C.b600]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _C.btn,
                ),
                child: const Text('Try Again',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(width: 14),
            _PressBtn(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.border, width: 1.5)),
                child: const Text('Go Back',
                    style: TextStyle(
                        color: _C.inkMid,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final isFiltered = _filterStatus != 'all';
    final label = isFiltered
        ? _filterStatus[0].toUpperCase() + _filterStatus.substring(1)
        : '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_C.b50, _C.b100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _C.b700.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Icon(
                isFiltered
                    ? Icons.filter_alt_off_rounded
                    : Icons.receipt_long_rounded,
                color: _C.b400,
                size: 50),
          ),
          const SizedBox(height: 22),
          Text(isFiltered ? 'No $label Orders' : 'No Orders Yet',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _C.ink,
                  letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'No orders with this status.\nTry a different filter.'
                : 'Your order history will appear here\nonce you start shopping.',
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 13, color: _C.inkSub, height: 1.55),
          ),
          const SizedBox(height: 28),
          _PressBtn(
            onTap: () => isFiltered
                ? setState(() => _filterStatus = 'all')
                : Navigator.pop(context),
            child: AnimatedBuilder(
              animation: _shimCtrl,
              builder: (_, __) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [_C.b900, _C.b700, _C.b600]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _C.btn,
                ),
                child: Stack(children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: FractionallySizedBox(
                        widthFactor: 0.38,
                        alignment: Alignment((_shimCtrl.value * 3.4) - 1.7, 0),
                        child: Container(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                          Colors.white.withOpacity(0),
                          Colors.white.withOpacity(0.10),
                          Colors.white.withOpacity(0),
                        ]))),
                      ),
                    ),
                  ),
                  Text(isFiltered ? 'Show All Orders' : 'Start Shopping',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ORDER CARD
// ═══════════════════════════════════════════════════════════════
class _OrderCard extends StatefulWidget {
  final Orders order;
  final int index;
  final Function(Orders)? onReorder;
  final AnimationController shimCtrl;
  final void Function(Orders) onViewDetails;
  final void Function(Orders) onReorderTap;

  const _OrderCard({
    super.key,
    required this.order,
    required this.index,
    required this.onReorder,
    required this.shimCtrl,
    required this.onViewDetails,
    required this.onReorderTap,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _slide = Tween<Offset>(begin: const Offset(0, 0.30), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * 75), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.order.orderId)
              .snapshots(),
          builder: (_, snap) {
            Orders order = widget.order;
            String status = order.status?.toLowerCase() ?? 'pending';
            if (snap.hasData && snap.data!.exists) {
              final data = snap.data!.data() as Map<String, dynamic>?;
              if (data != null) {
                status = data['status']?.toString().toLowerCase() ?? status;
                order = order.copyWith(status: data['status'] ?? order.status);
              }
            }
            return _buildCard(order, status);
          },
        ),
      ),
    );
  }

  Widget _buildCard(Orders order, String status) {
    final items = order.items;
    final totalAmount = order.totalAmount ?? 0.0;
    final orderDate = order.orderDate ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.border, width: 1),
        boxShadow: _C.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: _PressBtn(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _expanded = !_expanded);
          },
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // ── Top row ───────────────────────────────────────
                Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_C.b900, _C.b700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${order.orderId}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _C.ink,
                              letterSpacing: -0.2),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(_fmtDate(orderDate),
                          style: const TextStyle(
                              fontSize: 11,
                              color: _C.inkSub,
                              fontWeight: FontWeight.w500)),
                    ],
                  )),
                  _StatusBadge(status: status),
                ]),

                const SizedBox(height: 14),

                // ── Mini timeline ────────────────────────────────
                _MiniTimeline(status: status),

                const SizedBox(height: 14),

                // ── Item preview ─────────────────────────────────
                if (items.isNotEmpty) ...[
                  ...List.generate(
                    items.length < 2 ? items.length : 2,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: _C.b400, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                          '${items[i].product?.name ?? 'Product'} × ${items[i].quantity ?? 0}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: _C.inkMid,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                      ]),
                    ),
                  ),
                  if (items.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2, left: 14),
                      child: Text(
                        '+ ${items.length - 2} more item${items.length - 2 != 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: _C.b500,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],

                // ── Total + expand ────────────────────────────────
                Row(children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        gradient:
                            const LinearGradient(colors: [_C.b900, _C.b700]),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.70),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          Text('₦${totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _expanded ? _C.b50 : _C.surf,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.border, width: 1),
                    ),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more_rounded,
                          color: _expanded ? _C.b700 : _C.inkSub, size: 20),
                    ),
                  ),
                ]),
              ]),
            ),

            // ── Expanded actions ──────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Container(
                      decoration: BoxDecoration(
                        color: _C.surf,
                        border:
                            Border(top: BorderSide(color: _C.border, width: 1)),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Expanded(
                          child: _PressBtn(
                            onTap: () => widget.onViewDetails(order),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _C.b200, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                      color: _C.b700.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      color: _C.b700, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Details',
                                      style: TextStyle(
                                          color: _C.b700,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (status == 'delivered' &&
                            widget.onReorder != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PressBtn(
                              onTap: () => widget.onReorderTap(order),
                              child: AnimatedBuilder(
                                animation: widget.shimCtrl,
                                builder: (_, __) => Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [_C.b900, _C.b700, _C.b600]),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: _C.btn,
                                  ),
                                  child: Stack(children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: FractionallySizedBox(
                                          widthFactor: 0.40,
                                          alignment: Alignment(
                                              (widget.shimCtrl.value * 3.4) -
                                                  1.7,
                                              0),
                                          child: Container(
                                              decoration: BoxDecoration(
                                                  gradient:
                                                      LinearGradient(colors: [
                                            Colors.white.withOpacity(0),
                                            Colors.white.withOpacity(0.10),
                                            Colors.white.withOpacity(0),
                                          ]))),
                                        ),
                                      ),
                                    ),
                                    Center(
                                        child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.replay_rounded,
                                            color: Colors.white, size: 15),
                                        const SizedBox(width: 6),
                                        const Text('Reorder',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    )),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ]),
                    )
                  : const SizedBox.shrink(),
            ),
          ]),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final mn = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${m[d.month - 1]} ${d.year}  •  $h:$mn';
  }
}

// ═══════════════════════════════════════════════════════════════
//  STATUS BADGE
// ═══════════════════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = status.isEmpty
        ? 'pending'
        : (status[0].toUpperCase() + status.substring(1));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _C.statusBg(status),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _C.statusColor(status).withOpacity(0.28), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_C.statusIcon(status), color: _C.statusColor(status), size: 12),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: _C.statusColor(status),
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.1)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MINI TIMELINE
// ═══════════════════════════════════════════════════════════════
class _MiniTimeline extends StatelessWidget {
  final String status;
  const _MiniTimeline({required this.status});

  static const _steps = [
    'pending',
    'confirmed',
    'preparing',
    'on the way',
    'delivered'
  ];

  int get _activeIdx {
    if (status == 'cancelled') return -1;
    final i = _steps.indexOf(status);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _C.redLt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.red.withOpacity(0.25), width: 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cancel_rounded, color: _C.red, size: 14),
          const SizedBox(width: 6),
          const Text('Order Cancelled',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _C.red)),
        ]),
      );
    }

    final active = _activeIdx;
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final isActive = i ~/ 2 < active;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 2,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(colors: [_C.b700, _C.b500])
                    : null,
                color: isActive ? null : _C.border,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        } else {
          final idx = i ~/ 2;
          final isOn = idx <= active;
          final isCurr = idx == active;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: isCurr ? 20 : 13,
            height: isCurr ? 20 : 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isOn
                  ? const LinearGradient(
                      colors: [_C.b800, _C.b600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)
                  : null,
              color: isOn ? null : _C.border,
              boxShadow: isCurr
                  ? [
                      BoxShadow(
                          color: _C.b700.withOpacity(0.38),
                          blurRadius: 8,
                          spreadRadius: 1)
                    ]
                  : [],
            ),
            child: isOn
                ? Icon(isCurr ? Icons.circle : Icons.check_rounded,
                    color: Colors.white, size: isCurr ? 9 : 8)
                : null,
          );
        }
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BACKGROUND
// ═══════════════════════════════════════════════════════════════
class _Background extends StatelessWidget {
  final Animation<double> bgScale;
  final AnimationController orbitCtrl;
  final Size screenSize;

  const _Background({
    required this.bgScale,
    required this.orbitCtrl,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    final s = screenSize;
    return Positioned.fill(
      child: Stack(children: [
        Container(color: Colors.white),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ScaleTransition(
            scale: bgScale,
            alignment: Alignment.topCenter,
            child: Container(
              height: s.height * 0.27,
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
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -s.height * 0.06,
          left: s.width * 0.5 - 160,
          child: AnimatedBuilder(
            animation: orbitCtrl,
            builder: (_, __) => Transform.rotate(
              angle: orbitCtrl.value * 2 * math.pi,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.035), width: 36)),
              ),
            ),
          ),
        ),
        Positioned(
          top: s.height * 0.01,
          left: s.width * 0.5 - 95,
          child: AnimatedBuilder(
            animation: orbitCtrl,
            builder: (_, __) => Transform.rotate(
              angle: -orbitCtrl.value * 2 * math.pi * 0.55,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.025), width: 18)),
              ),
            ),
          ),
        ),
        Positioned(
            top: -40,
            left: -40,
            child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2563EB).withOpacity(0.13)))),
        Positioned(
            top: -20,
            right: -30,
            child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF60A5FA).withOpacity(0.10)))),
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: s.height * 0.14,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFFEFF6FF).withOpacity(0.35),
                  ],
                ),
              ),
            )),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PRESSABLE WRAPPER
// ═══════════════════════════════════════════════════════════════
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
