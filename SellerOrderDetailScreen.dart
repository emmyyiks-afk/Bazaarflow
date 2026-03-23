// ════════════════════════════════════════════════════════════════════════════
//  FILE: seller_order_detail_and_profile.dart
//  Contains: SellerOrderDetailScreen + SellerProfileScreen
// ════════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  SELLER ORDER DETAIL SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class SellerOrderDetailScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final String sellerId;

  const SellerOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.data,
    required this.sellerId,
  });

  @override
  State<SellerOrderDetailScreen> createState() =>
      _SellerOrderDetailScreenState();
}

class _SellerOrderDetailScreenState extends State<SellerOrderDetailScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isUpdating = false;
  late Map<String, dynamic> _data;

  static const _steps = [
    ('pending', 'Pending', Icons.hourglass_top_rounded),
    ('confirmed', 'Confirmed', Icons.autorenew_rounded),
    ('preparing', 'Preparing', Icons.restaurant_rounded),
    ('on the way', 'On the Way', Icons.delivery_dining_rounded),
    ('delivered', 'Delivered', Icons.check_circle_rounded),
    ('cancelled', 'Cancelled', Icons.cancel_rounded),
  ];

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _data = Map.from(widget.data);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  String get _status => (_data['status'] ?? 'pending').toString().toLowerCase();
  int get _stepIdx => _steps.indexWhere((s) => s.$1 == _status);

  Color _statusColor(String s) {
    switch (s) {
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
    switch (s) {
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: StreamBuilder<DocumentSnapshot>(
          stream: _db.collection('orders').doc(widget.orderId).snapshots(),
          builder: (_, snap) {
            if (snap.hasData && snap.data!.exists) {
              _data = snap.data!.data() as Map<String, dynamic>;
            }
            return FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Column(
                        children: [
                          const SizedBox(height: 18),
                          _buildCurrentStatus(),
                          const SizedBox(height: 16),
                          _buildTimeline(),
                          const SizedBox(height: 16),
                          _buildUpdateSection(),
                          const SizedBox(height: 16),
                          _buildCustomerInfo(),
                          const SizedBox(height: 16),
                          _buildMyItems(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final mq = MediaQuery.of(context);
    final id = _data['orderId'] ?? widget.orderId;
    final shortId = id.length > 10 ? id.substring(id.length - 10) : id;

    return Stack(
      children: [
        Container(
          height: mq.padding.top + 80,
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
              bottomLeft: Radius.circular(26),
              bottomRight: Radius.circular(26),
            ),
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  _GlassBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order Detail',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.3,
                            )),
                        Text('#$shortId',
                            style: TextStyle(
                              color: Colors.white.withOpacity(.68),
                              fontSize: 11,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(.28), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34D399),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text('Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStatus() {
    final color = _statusColor(_status);
    final bg = _statusBg(_status);
    final label = _status.isEmpty
        ? 'Unknown'
        : _status[0].toUpperCase() + _status.substring(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(.16),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(.28), width: 1.5),
            ),
            child: Icon(_steps[_stepIdx >= 0 ? _stepIdx : 0].$3,
                color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Status',
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withOpacity(.70),
                      fontWeight: FontWeight.w600,
                    )),
                Text(label,
                    style: TextStyle(
                      fontSize: 20,
                      color: color,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.3,
                    )),
              ],
            ),
          ),
          if (_isUpdating)
            SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(strokeWidth: 2.5, color: color)),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final activeSteps = _steps.where((s) => s.$1 != 'cancelled').toList();
    final isCancelled = _status == 'cancelled';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.timeline_rounded,
            label: 'Progress',
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF1A56DB),
          ),
          const SizedBox(height: 14),
          if (isCancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFDC2626).withOpacity(.25), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block_rounded, color: Color(0xFFDC2626), size: 15),
                  SizedBox(width: 6),
                  Text('This order was cancelled',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            )
          else
            Column(
              children: List.generate(activeSteps.length, (i) {
                final step = activeSteps[i];
                final stepIdx = _steps.indexWhere((s) => s.$1 == step.$1);
                final done = stepIdx <= _stepIdx;
                final active = stepIdx == _stepIdx;
                final isLast = i == activeSteps.length - 1;
                final color = _statusColor(step.$1);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: done
                                  ? (active ? color : const Color(0xFF10B981))
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: done
                                    ? (active ? color : const Color(0xFF10B981))
                                    : const Color(0xFFD4E0F7),
                                width: done ? 0 : 1.5,
                              ),
                              boxShadow: done
                                  ? [
                                      BoxShadow(
                                          color: (active
                                                  ? color
                                                  : const Color(0xFF10B981))
                                              .withOpacity(.30),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2))
                                    ]
                                  : [],
                            ),
                            child: done
                                ? Icon(active ? step.$3 : Icons.check_rounded,
                                    color: Colors.white, size: 12)
                                : null,
                          ),
                          if (!isLast)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 2,
                              height: 32,
                              color: done && stepIdx < _stepIdx
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFD4E0F7),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.$2,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: active
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: active
                                      ? color
                                      : done
                                          ? const Color(0xFF0A1628)
                                          : const Color(0xFF8FA2C4),
                                )),
                            if (active)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(.12),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text('Current',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildUpdateSection() {
    final done = _status == 'delivered' || _status == 'cancelled';
    if (done) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _status == 'delivered'
              ? const Color(0xFFD1FAE5)
              : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (_status == 'delivered'
                    ? const Color(0xFF10B981)
                    : const Color(0xFFDC2626))
                .withOpacity(.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _status == 'delivered'
                  ? Icons.check_circle_rounded
                  : Icons.lock_rounded,
              color: _status == 'delivered'
                  ? const Color(0xFF10B981)
                  : const Color(0xFFDC2626),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _status == 'delivered'
                    ? 'Order complete — no further updates needed'
                    : 'Order cancelled — no further updates',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _status == 'delivered'
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final nextIdx = _stepIdx + 1;
    final hasNext =
        nextIdx < _steps.length && _steps[nextIdx].$1 != 'cancelled';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.bolt_rounded,
            label: 'Update Status',
            iconBg: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 14),
          if (hasNext) ...[
            _PressBtn(
              onTap: () => _confirmUpdate(_steps[nextIdx].$1),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _statusColor(_steps[nextIdx].$1),
                      _statusColor(_steps[nextIdx].$1).withOpacity(.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color:
                            _statusColor(_steps[nextIdx].$1).withOpacity(.38),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                        spreadRadius: -3)
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_steps[nextIdx].$3, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('Mark as ${_steps[nextIdx].$2}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          _PressBtn(
            onTap: () => _confirmUpdate('cancelled'),
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: const Color(0xFFDC2626).withOpacity(.30), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel_rounded,
                      color: Color(0xFFDC2626), size: 16),
                  SizedBox(width: 6),
                  Text('Cancel Order',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    final name = _data['userName'] ?? _data['userEmail'] ?? 'Customer';
    final address = _data['checkoutInfo']?['deliveryAddress'] ?? '';
    final phone = _data['checkoutInfo']?['phoneNumber'] ?? '';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.person_rounded,
            label: 'Customer',
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF1A56DB),
          ),
          const SizedBox(height: 12),
          _InfoRow(
              icon: Icons.person_outline_rounded, label: 'Name', value: name),
          _InfoRow(
              icon: Icons.location_on_rounded,
              label: 'Address',
              value: address),
          _InfoRow(
              icon: Icons.phone_rounded,
              label: 'Phone',
              value: phone,
              isLast: true),
        ],
      ),
    );
  }

  // ✅ FIXED — checks sellerIds as a List, not singular sellerId
  Widget _buildMyItems() {
    final allItems = (_data['items'] as List? ?? []);

    final myItems = allItems.where((item) {
      final m = item as Map<String, dynamic>? ?? {};

      // Check inside sellerIds array (new orders)
      final ids =
          (m['sellerIds'] as List?)?.map((e) => e.toString()).toList() ?? [];

      // Fallback: also check singular sellerId (old orders)
      final singleId = m['sellerId']?.toString() ?? '';

      return ids.contains(widget.sellerId) || singleId == widget.sellerId;
    }).toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionHeader(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Your Items',
                  iconBg: const Color(0xFFD1FAE5),
                  iconColor: const Color(0xFF059669),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                ),
                child: Text(
                  '${myItems.length} item${myItems.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1A56DB),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Empty state when no items match this seller
          if (myItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4E0F7), width: 1),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inbox_rounded, color: Color(0xFF8FA2C4), size: 28),
                  SizedBox(height: 6),
                  Text('No items from your shop in this order',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8FA2C4),
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
            )
          else
            ...myItems.asMap().entries.map((entry) {
              final item = entry.value as Map<String, dynamic>? ?? {};
              final name = item['productName'] ?? 'Item';
              final qty = item['quantity'] ?? 0;
              final price = ((item['price'] ?? 0) as num).toDouble();
              final isLast = entry.key == myItems.length - 1;

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FF),
                      borderRadius: BorderRadius.circular(13),
                      border:
                          Border.all(color: const Color(0xFFD4E0F7), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fastfood_rounded,
                              color: Color(0xFF60A5FA), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0A1628),
                                  )),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text('Qty: $qty',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF1A56DB),
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ],
                          ),
                        ),
                        Text('₦${(price * qty).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A1628),
                            )),
                      ],
                    ),
                  ),
                  if (!isLast) const SizedBox(height: 7),
                ],
              );
            }),
        ],
      ),
    );
  }

  void _confirmUpdate(String newStatus) {
    final color = _statusColor(newStatus);
    final label = newStatus[0].toUpperCase() + newStatus.substring(1);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                _steps
                    .firstWhere((s) => s.$1 == newStatus,
                        orElse: () => _steps.first)
                    .$3,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text('Update to $label',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A1628),
                )),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 8),
          child: Text('This will notify the customer.',
              style: TextStyle(
                color: Color(0xFF3D5170),
                fontSize: 13,
                height: 1.5,
              )),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(
                  color: Color(0xFF8FA2C4),
                  fontWeight: FontWeight.w600,
                )),
          ),
          _PressBtn(
            onTap: () {
              Navigator.pop(context);
              _updateStatus(newStatus);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Text('Confirm',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      final orderDoc = await _db.collection('orders').doc(widget.orderId).get();
      final userId = orderDoc.data()?['userId'] as String?;

      // 1. Update global orders collection
      await _db.collection('orders').doc(widget.orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _currentUser?.email ?? 'seller',
      });

      // 2. Update user's personal subcollection
      if (userId != null && userId.isNotEmpty) {
        await _db
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(widget.orderId)
            .update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Write notification to Firestore
      _db.collection('notifications').add({
        'orderId': widget.orderId,
        'userId': userId,
        'status': newStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Updated to: $newStatus'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SELLER PROFILE SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});
  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  final _currCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showCurr = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final email = _user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'S';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: mq.padding.top + 110,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF060F2E),
                        Color(0xFF0D2260),
                        Color(0xFF1A56DB),
                        Color(0xFF3B82F6),
                      ],
                      stops: [0.0, 0.25, 0.62, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _GlassBtn(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('My Account',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(.30),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(initial,
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
                                    Text(email,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis),
                                    Container(
                                      margin: const EdgeInsets.only(top: 3),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(.14),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('Seller',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          )),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF1A56DB),
                                  Color(0xFF3B82F6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text('Change Password',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0A1628),
                              )),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: const Color(0xFFDC2626).withOpacity(.28),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Color(0xFFDC2626), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_error!,
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    )),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _error = null),
                                child: const Icon(Icons.close_rounded,
                                    color: Color(0xFFDC2626), size: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _buildField(
                        'Current Password',
                        _currCtrl,
                        Icons.lock_outline_rounded,
                        _showCurr,
                        () => setState(() => _showCurr = !_showCurr),
                        (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        'New Password',
                        _newCtrl,
                        Icons.lock_rounded,
                        _showNew,
                        () => setState(() => _showNew = !_showNew),
                        (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 8) return 'Min 8 characters';
                          if (v == _currCtrl.text) {
                            return 'Must be different from current';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        'Confirm New Password',
                        _confirmCtrl,
                        Icons.lock_rounded,
                        _showConfirm,
                        () => setState(() => _showConfirm = !_showConfirm),
                        (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v != _newCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      _PressBtn(
                        onTap: _loading ? () {} : _changePassword,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: _loading
                                ? const LinearGradient(colors: [
                                    Color(0xFF8FA2C4),
                                    Color(0xFF8FA2C4),
                                  ])
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF060F2E),
                                      Color(0xFF1A56DB),
                                      Color(0xFF3B82F6),
                                    ],
                                    stops: [0.0, .5, 1.0],
                                  ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: _loading
                                ? []
                                : const [
                                    BoxShadow(
                                      color: Color(0x551A56DB),
                                      blurRadius: 18,
                                      offset: Offset(0, 6),
                                      spreadRadius: -3,
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.lock_reset_rounded,
                                          color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Update Password',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          )),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: _sendResetEmail,
                          child: const Text(
                            'Forgot password? Send reset email',
                            style: TextStyle(
                              color: Color(0xFF1A56DB),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon,
    bool show,
    VoidCallback toggle,
    String? Function(String?) validator,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Text(label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A1628),
              )),
        ]),
        const SizedBox(height: 8),
        _FieldWidget(
          controller: ctrl,
          icon: icon,
          obscureText: !show,
          suffixIcon: GestureDetector(
            onTap: toggle,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                show ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: const Color(0xFF8FA2C4),
                size: 19,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _user?.email;
      if (_user == null || email == null) {
        throw Exception('No session');
      }
      final cred = EmailAuthProvider.credential(
          email: email, password: _currCtrl.text.trim());
      await _user!.reauthenticateWithCredential(cred);
      await _user!.updatePassword(_newCtrl.text.trim());

      HapticFeedback.heavyImpact();
      if (mounted) {
        _currCtrl.clear();
        _newCtrl.clear();
        _confirmCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _err(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendResetEmail() async {
    final email = _user?.email;
    if (email == null) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Reset email sent to $email'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  String _err(String code) {
    switch (code) {
      case 'wrong-password':
        return 'Current password is incorrect.';
      case 'weak-password':
        return 'New password too weak (min 8 chars).';
      case 'requires-recent-login':
        return 'Session expired. Log out and log in again.';
      default:
        return 'Failed to update. Try again.';
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SHARED LOCAL WIDGETS
// ═════════════════════════════════════════════════════════════════════════════
class _FieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _FieldWidget({
    required this.controller,
    required this.icon,
    required this.obscureText,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<_FieldWidget> createState() => _FieldWidgetState();
}

class _FieldWidgetState extends State<_FieldWidget> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _focused ? Colors.white : const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _focused ? const Color(0xFF2563EB) : const Color(0xFFD4E0F7),
          width: _focused ? 1.8 : 1.2,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(.16),
                    blurRadius: 12,
                    offset: const Offset(0, 3))
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscureText,
        validator: widget.validator,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF0A1628),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(widget.icon,
              color:
                  _focused ? const Color(0xFF1A56DB) : const Color(0xFF8FA2C4),
              size: 19),
          suffixIcon: widget.suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          errorStyle: const TextStyle(
            color: Color(0xFFDC2626),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4E0F7), width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x141A56DB), blurRadius: 20, offset: Offset(0, 5)),
          BoxShadow(
              color: Color(0x0A1A56DB), blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A1628),
              letterSpacing: -.2,
            )),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: const Color(0xFF1A56DB), size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8FA2C4),
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(value.isEmpty ? '—' : value,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0A1628),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Container(height: 1, color: const Color(0xFFD4E0F7)),
      ],
    );
  }
}

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
