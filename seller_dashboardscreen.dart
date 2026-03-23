import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iyadunni_shopmore/service/SellerOrderDetailScreen.dart';
import 'package:iyadunni_shopmore/service/admin_loginscreen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  SELLER DASHBOARD SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class SellerDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> sellerData;
  final String uid;

  const SellerDashboardScreen({
    super.key,
    required this.sellerData,
    required this.uid,
  });

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with TickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  String _filter = 'all';

  late final AnimationController _headerCtrl;
  late final AnimationController _orbitCtrl;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _headerFade;

  static const _filterTabs = [
    ('all', 'All', Icons.list_rounded),
    ('pending', 'Pending', Icons.hourglass_top_rounded),
    ('confirmed', 'Confirmed', Icons.autorenew_rounded),
    ('preparing', 'Preparing', Icons.restaurant_rounded),
    ('on the way', 'On Way', Icons.delivery_dining_rounded),
    ('delivered', 'Delivered', Icons.check_circle_rounded),
    ('cancelled', 'Cancelled', Icons.cancel_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _orbitCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 28))
          ..repeat();

    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    _headerFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    _headerCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String get _shopName =>
      widget.sellerData['shopName'] ?? widget.sellerData['name'] ?? 'My Shop';

  String get _initial => _shopName[0].toUpperCase();

  // Firestore stream — only this seller's orders (no orderBy = no index needed)
  Stream<QuerySnapshot> get _ordersStream => _db
      .collection('orders')
      .where('sellerIds', arrayContains: widget.uid)
      .snapshots();

  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildHeader(),
            _buildFilterRow(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final mq = MediaQuery.of(context);
    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _headerFade,
        child: Stack(
          children: [
            // Gradient blob
            Container(
              height: mq.padding.top + 130,
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
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),

            // Orbiting ring decoration
            Positioned(
              top: -40,
              left: mq.size.width * .5 - 140,
              child: AnimatedBuilder(
                animation: _orbitCtrl,
                builder: (_, __) => Transform.rotate(
                  angle: _orbitCtrl.value * 2 * math.pi,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(.034), width: 34),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Shop avatar
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(.32),
                                  width: 1.5),
                            ),
                            child: Center(
                              child: Text(_initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  )),
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_shopName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -.3,
                                    )),
                                Text(
                                  FirebaseAuth.instance.currentUser?.email ??
                                      '',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.65),
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Profile button
                          _GlassBtn(
                            icon: Icons.manage_accounts_rounded,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const SellerProfileScreen())),
                          ),
                          const SizedBox(width: 8),
                          // Logout
                          _GlassBtn(
                            icon: Icons.logout_rounded,
                            onTap: _logout,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildStatsStrip(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats strip ────────────────────────────────────────────────────────────
  Widget _buildStatsStrip() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ordersStream,
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        final total = docs.length;
        final pending =
            docs.where((d) => (d['status'] ?? '') == 'pending').length;
        final delivered =
            docs.where((d) => (d['status'] ?? '') == 'delivered').length;

        return Row(
          children: [
            _MiniStat(
                label: 'Total',
                value: '$total',
                icon: Icons.receipt_long_rounded),
            _divider(),
            _MiniStat(
                label: 'Pending',
                value: '$pending',
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFFFBBF24)),
            _divider(),
            _MiniStat(
                label: 'Done',
                value: '$delivered',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF34D399)),
          ],
        );
      },
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        color: Colors.white.withOpacity(.22),
      );

  // ── Filter chips ───────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filterTabs.map((tab) {
            final active = _filter == tab.$1;
            final color = tab.$1 == 'all'
                ? const Color(0xFF1A56DB)
                : _statusColor(tab.$1);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _filter = tab.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? color : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: active ? color : const Color(0xFFD4E0F7),
                      width: active ? 0 : 1.2,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: color.withOpacity(.30),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                                spreadRadius: -2)
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.$3,
                          size: 13, color: active ? Colors.white : color),
                      const SizedBox(width: 5),
                      Text(tab.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                active ? Colors.white : const Color(0xFF3D5170),
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Order list body ────────────────────────────────────────────────────────
  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ordersStream,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Color(0xFF1A56DB)));
        }

        if (snap.hasError) {
          return _centred(_indexError(snap.error.toString()));
        }

        var docs = snap.data?.docs ?? [];

        // Sort newest first in Dart — no Firestore index needed
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDate = aData['orderDate']?.toString() ?? '';
          final bDate = bData['orderDate']?.toString() ?? '';
          return bDate.compareTo(aDate);
        });

        // Apply status filter
        if (_filter != 'all') {
          docs = docs
              .where((d) =>
                  (d['status'] ?? '').toString().toLowerCase() == _filter)
              .toList();
        }

        if (docs.isEmpty) return _centred(_emptyWidget());

        return ListView.builder(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _SellerOrderCard(
              key: ValueKey(doc.id),
              orderId: doc.id,
              data: data,
              sellerId: widget.uid,
              index: i,
              onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => SellerOrderDetailScreen(
                        orderId: doc.id, data: data, sellerId: widget.uid),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 300),
                  )),
            );
          },
        );
      },
    );
  }

  Widget _centred(Widget w) =>
      Center(child: Padding(padding: const EdgeInsets.all(28), child: w));

  Widget _emptyWidget() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Color(0xFF60A5FA), size: 44),
          ),
          const SizedBox(height: 20),
          const Text('No orders yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0A1628),
                letterSpacing: -.3,
              )),
          const SizedBox(height: 8),
          Text(
            _filter == 'all'
                ? 'Orders for your products will appear here.'
                : 'No $_filter orders right now.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF8FA2C4), height: 1.5),
          ),
        ],
      );

  Widget _indexError(String error) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(.30), width: 1.5),
            ),
            child: const Icon(Icons.build_circle_rounded,
                color: Color(0xFFF59E0B), size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Index Required',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0A1628),
              )),
          const SizedBox(height: 8),
          const Text(
            'Firestore needs a composite index.\n'
            'Check the console for a link to create it —\n'
            'takes about 2 minutes.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 12, color: Color(0xFF8FA2C4), height: 1.6),
          ),
        ],
      );

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A1628),
            )),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: Color(0xFF3D5170))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(
                  color: Color(0xFF8FA2C4),
                  fontWeight: FontWeight.w600,
                )),
          ),
          _PressBtn(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Log Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  )),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      // ✅ FIX 1 — navigates to correct SellerLoginScreen
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SellerLoginScreen()),
          (r) => false);
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF2563EB);
      case 'preparing':
        return const Color(0xFF7C3AED);
      case 'on the way':
        return const Color(0xFF0891B2);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF8FA2C4);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SELLER ORDER CARD
// ═══════════════════════════════════════════════════════════════════════════
class _SellerOrderCard extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final String sellerId;
  final int index;
  final VoidCallback onTap;

  const _SellerOrderCard({
    super.key,
    required this.orderId,
    required this.data,
    required this.sellerId,
    required this.index,
    required this.onTap,
  });

  @override
  State<_SellerOrderCard> createState() => _SellerOrderCardState();
}

class _SellerOrderCardState extends State<_SellerOrderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _slide = Tween<Offset>(begin: const Offset(0, .18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: (widget.index * 70).clamp(0, 420)),
        () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF2563EB);
      case 'preparing':
        return const Color(0xFF7C3AED);
      case 'on the way':
        return const Color(0xFF0891B2);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF8FA2C4);
    }
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'confirmed':
        return const Color(0xFFEFF6FF);
      case 'preparing':
        return const Color(0xFFF5F3FF);
      case 'on the way':
        return const Color(0xFFECFEFF);
      case 'delivered':
        return const Color(0xFFD1FAE5);
      case 'cancelled':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF4F8FF);
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'confirmed':
        return Icons.autorenew_rounded;
      case 'preparing':
        return Icons.restaurant_rounded;
      case 'on the way':
        return Icons.delivery_dining_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}  '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final status = (d['status'] ?? 'pending').toString().toLowerCase();
    final id = d['orderId'] ?? widget.orderId;
    final shortId = id.length > 10 ? id.substring(id.length - 10) : id;
    final name = d['userName'] ?? d['userEmail'] ?? 'Customer';
    final total = ((d['totalAmount'] ?? 0) as num).toDouble();
    final date = d['orderDate'] != null
        ? (d['orderDate'] as Timestamp).toDate()
        : DateTime.now();

    // ✅ FIX 3 — checks sellerIds List AND fallback singular sellerId
    final allItems = (d['items'] as List? ?? []);
    final myItems = allItems.where((item) {
      final m = item as Map<String, dynamic>? ?? {};

      // Check sellerIds array (new orders)
      final ids =
          (m['sellerIds'] as List?)?.map((e) => e.toString()).toList() ?? [];

      // Fallback: singular sellerId field (old orders)
      final singleId = m['sellerId']?.toString() ?? '';

      return ids.contains(widget.sellerId) || singleId == widget.sellerId;
    }).toList();

    final color = _statusColor(status);
    final bg = _statusBg(status);
    final icon = _statusIcon(status);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: _PressBtn(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4E0F7), width: 1),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x141A56DB),
                    blurRadius: 20,
                    offset: Offset(0, 5)),
                BoxShadow(
                    color: Color(0x0A1A56DB),
                    blurRadius: 5,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                // Status banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color.withOpacity(.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: color.withOpacity(.28), width: 1),
                        ),
                        child: Icon(icon, color: color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.isEmpty
                                  ? 'Unknown'
                                  : status[0].toUpperCase() +
                                      status.substring(1),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Text(_formatDate(date),
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF8FA2C4))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.75),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: color.withOpacity(.20), width: 1),
                        ),
                        child: Text('#$shortId',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: color,
                              letterSpacing: .4,
                            )),
                      ),
                    ],
                  ),
                ),

                // Card body
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0A1628),
                                    )),
                                Text(
                                  '${myItems.length} of your item${myItems.length != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF8FA2C4)),
                                ),
                              ],
                            ),
                          ),
                          Text('₦${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0A1628),
                                letterSpacing: -.3,
                              )),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded,
                              color: Color(0xFF8FA2C4), size: 18),
                        ],
                      ),

                      // Items preview chips
                      if (myItems.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (int i = 0; i < myItems.length.clamp(0, 3); i++)
                              _ItemChip(
                                '${(myItems[i] as Map)['productName'] ?? 'Item'}'
                                ' ×${(myItems[i] as Map)['quantity'] ?? 1}',
                              ),
                            if (myItems.length > 3)
                              _ItemChip('+${myItems.length - 3} more',
                                  isMore: true),
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MINI STAT
// ═══════════════════════════════════════════════════════════════════════════
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(.80), size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                  )),
              Text(label,
                  style: TextStyle(
                    color: color.withOpacity(.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ITEM CHIP
// ═══════════════════════════════════════════════════════════════════════════
class _ItemChip extends StatelessWidget {
  final String label;
  final bool isMore;
  const _ItemChip(this.label, {this.isMore = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isMore ? const Color(0xFFF4F8FF) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isMore ? const Color(0xFFD4E0F7) : const Color(0xFFBFDBFE),
          width: 1,
        ),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isMore ? const Color(0xFF8FA2C4) : const Color(0xFF1A56DB),
          )),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  GLASS ICON BUTTON
// ═══════════════════════════════════════════════════════════════════════════
class _GlassBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassBtn({required this.icon, required this.onTap});
  @override
  State<_GlassBtn> createState() => _GlassBtnState();
}

class _GlassBtnState extends State<_GlassBtn> {
  bool _d = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _d = true),
      onTapUp: (_) {
        setState(() => _d = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _d = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _d
              ? Colors.white.withOpacity(.28)
              : Colors.white.withOpacity(.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(.26), width: 1),
        ),
        child: Icon(widget.icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PRESS BUTTON WRAPPER
// ═══════════════════════════════════════════════════════════════════════════
class _PressBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressBtn({required this.child, required this.onTap});
  @override
  State<_PressBtn> createState() => _PressBtnState();
}

class _PressBtnState extends State<_PressBtn> {
  bool _d = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _d = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _d = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _d = false),
      child: AnimatedScale(
        scale: _d ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: widget.child,
      ),
    );
  }
}
