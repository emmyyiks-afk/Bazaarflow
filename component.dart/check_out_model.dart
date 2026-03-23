import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iyadunni_shopmore/component.dart/cart_items.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  CHECKOUT INFORMATION MODEL
// ═══════════════════════════════════════════════════════════════════════════
class CheckoutInfo {
  final String deliveryAddress;
  final String phoneNumber;
  final String paymentMethod;
  final String? notes;
  final DateTime deliveryTime;

  CheckoutInfo({
    required this.deliveryAddress,
    required this.phoneNumber,
    required this.paymentMethod,
    this.notes,
    required this.deliveryTime,
  });

  // ── JSON (ISO string dates — safe for local storage / non-Firestore use) ─
  Map<String, dynamic> toJson() {
    return {
      'deliveryAddress': deliveryAddress,
      'phoneNumber': phoneNumber,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'deliveryTime': deliveryTime.toIso8601String(),
    };
  }

  factory CheckoutInfo.fromJson(Map<String, dynamic> json) {
    return CheckoutInfo(
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash on Delivery',
      notes: json['notes']?.toString(),
      deliveryTime: _parseDateTime(json['deliveryTime']),
    );
  }

  // ── Firestore map (uses Timestamp for deliveryTime) ──────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'deliveryAddress': deliveryAddress,
      'phoneNumber': phoneNumber,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'deliveryTime': Timestamp.fromDate(deliveryTime),
    };
  }

  factory CheckoutInfo.fromFirestore(Map<String, dynamic> map) {
    return CheckoutInfo(
      deliveryAddress: map['deliveryAddress']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      paymentMethod: map['paymentMethod']?.toString() ?? 'Cash on Delivery',
      notes: map['notes']?.toString(),
      deliveryTime: _parseDateTime(map['deliveryTime']),
    );
  }

  // ── Helper: accepts Timestamp, ISO string, or null ───────────────────────
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ORDERS MODEL
// ═══════════════════════════════════════════════════════════════════════════
class Orders {
  String orderId;
  List<CartItem> items;
  double totalAmount;
  DateTime orderDate;
  String status;
  CheckoutInfo checkoutInfo;

  // User information
  String? userId;
  String? userEmail;
  String? userName;

  // Seller IDs — every unique sellerId across all items in this order.
  // Written at the TOP LEVEL of the Firestore document so the seller
  // dashboard query works:
  //   orders.where('sellerIds', arrayContains: currentSellerUid)
  List<String>? sellerIds;

  // Paystack payment reference — null for Cash on Delivery orders
  String? paystackReference;

  Orders({
    required this.orderId,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    required this.checkoutInfo,
    this.userId,
    this.userEmail,
    this.userName,
    this.sellerIds,
    this.paystackReference, // ← added
  });

  // ── Computed getters ────────────────────────────────────────────────────
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get formattedDate => '${orderDate.day.toString().padLeft(2, '0')}/'
      '${orderDate.month.toString().padLeft(2, '0')}/'
      '${orderDate.year}';

  String get formattedTime => '${orderDate.hour.toString().padLeft(2, '0')}:'
      '${orderDate.minute.toString().padLeft(2, '0')}';

  // ── JSON serialisation (ISO strings — for local / non-Firestore use) ─────
  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
      'checkoutInfo': checkoutInfo.toJson(),
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'sellerIds': sellerIds ?? <String>[],
      'paystackReference': paystackReference, // ← added
    };
  }

  factory Orders.fromJson(Map<String, dynamic> json) {
    return Orders(
      orderId: json['orderId']?.toString() ?? '',
      items: (json['items'] as List?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      orderDate: json['orderDate'] != null
          ? DateTime.parse(json['orderDate'].toString())
          : DateTime.now(),
      status: json['status']?.toString() ?? 'Pending',
      checkoutInfo: json['checkoutInfo'] != null
          ? CheckoutInfo.fromJson(json['checkoutInfo'] as Map<String, dynamic>)
          : CheckoutInfo(
              deliveryAddress: '',
              phoneNumber: '',
              paymentMethod: 'Cash on Delivery',
              deliveryTime: DateTime.now(),
            ),
      userId: json['userId']?.toString(),
      userEmail: json['userEmail']?.toString(),
      userName: json['userName']?.toString(),
      sellerIds:
          (json['sellerIds'] as List?)?.map((e) => e.toString()).toList(),
      paystackReference: json['paystackReference']?.toString(), // ← added
    );
  }

  // ── Firestore serialisation (uses Timestamps) ────────────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'orderDate': Timestamp.fromDate(orderDate),
      'status': status,
      'checkoutInfo': checkoutInfo.toFirestore(),
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'sellerIds': sellerIds ?? <String>[],
      'paystackReference': paystackReference, // ← added
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Orders.fromFirestore(Map<String, dynamic> data, String docId) {
    return Orders(
      orderId: data['orderId']?.toString() ?? docId,
      items: (data['items'] as List?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      orderDate: data['orderDate'] is Timestamp
          ? (data['orderDate'] as Timestamp).toDate()
          : DateTime.now(),
      status: data['status']?.toString() ?? 'Pending',
      checkoutInfo: data['checkoutInfo'] != null
          ? CheckoutInfo.fromFirestore(
              data['checkoutInfo'] as Map<String, dynamic>)
          : CheckoutInfo(
              deliveryAddress: '',
              phoneNumber: '',
              paymentMethod: 'Cash on Delivery',
              deliveryTime: DateTime.now(),
            ),
      userId: data['userId']?.toString(),
      userEmail: data['userEmail']?.toString(),
      userName: data['userName']?.toString(),
      sellerIds:
          (data['sellerIds'] as List?)?.map((e) => e.toString()).toList(),
      paystackReference: data['paystackReference']?.toString(), // ← added
    );
  }

  // ── copyWith ────────────────────────────────────────────────────────────
  Orders copyWith({
    String? orderId,
    List<CartItem>? items,
    double? totalAmount,
    DateTime? orderDate,
    String? status,
    CheckoutInfo? checkoutInfo,
    String? userId,
    String? userEmail,
    String? userName,
    List<String>? sellerIds,
    String? paystackReference, // ← added
  }) {
    return Orders(
      orderId: orderId ?? this.orderId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      checkoutInfo: checkoutInfo ?? this.checkoutInfo,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      sellerIds: sellerIds ?? this.sellerIds,
      paystackReference: paystackReference ?? this.paystackReference, // ← added
    );
  }

  @override
  String toString() {
    return 'Order #$orderId — Status: $status — '
        'Total: ₦$totalAmount — User: ${userEmail ?? userId} — '
        'Sellers: $sellerIds — Paystack Ref: $paystackReference';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CREATE ORDER HELPER
//  Call this from checkout instead of building Orders manually.
//  sellerIds is auto-extracted from cart items — no manual work needed.
// ═══════════════════════════════════════════════════════════════════════════
Orders createOrder({
  required List<CartItem> items,
  required double totalAmount,
  required CheckoutInfo checkoutInfo,
  String? userId,
  String? userEmail,
  String? userName,
  String? paystackReference, // ← added
}) {
  final now = DateTime.now();
  final orderId = 'ORD${now.millisecondsSinceEpoch}';

  // Auto-collect every unique sellerId from the cart items
  final List<String> sellerIds = items
      .expand((item) => item.product.sellerIds ?? <String>[])
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  return Orders(
    orderId: orderId,
    items: items,
    totalAmount: totalAmount,
    orderDate: now,
    status: paystackReference != null ? 'Paid' : 'Pending', // ← auto-set status
    checkoutInfo: checkoutInfo,
    userId: userId,
    userEmail: userEmail,
    userName: userName,
    sellerIds: sellerIds,
    paystackReference: paystackReference, // ← added
  );
}
