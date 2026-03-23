import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iyadunni_shopmore/component.dart/cart_items.dart';
import 'package:iyadunni_shopmore/component.dart/check_out_model.dart';
import 'package:iyadunni_shopmore/component.dart/product.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference get ordersCollection => _firestore.collection('orders');
  CollectionReference get productsCollection =>
      _firestore.collection('products');
  CollectionReference get usersCollection => _firestore.collection('users');

  // ══════════════════════════════════════════════════════════════════════════
  //  SAVE ORDER
  //  FIX 1 — writes top-level 'sellerIds' so the seller dashboard query works
  //  FIX 2 — saves item-level 'sellerIds' as a proper List (was saving the
  //           whole list object under the wrong key 'sellerId')
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> saveOrder(Orders order) async {
    try {
      if (order.userId == null || order.userId!.isEmpty) {
        throw Exception('User ID is required to save order');
      }

      print('💾 Saving order: ${order.orderId}');
      print('👤 User: ${order.userId}');

      // Collect every unique sellerId across all cart items
      final List<String> allSellerIds = order.items
          .expand((item) => item.product.sellerIds ?? <String>[])
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      print('🏪 Seller IDs in this order: $allSellerIds');

      final Map<String, dynamic> orderData = {
        'orderId': order.orderId,
        'userId': order.userId,
        'userEmail': order.userEmail,
        'userName': order.userName,

        // ✅ FIX 1 — top-level sellerIds used by seller dashboard query:
        //    .where('sellerIds', arrayContains: widget.uid)
        'sellerIds': allSellerIds,

        // ✅ FIX 2 — each item stores its own sellerIds as a proper List
        'items': order.items
            .map(
              (item) => {
                'productId': item.product.id,
                'productName': item.product.name,
                'price': item.product.price,
                'quantity': item.quantity,
                'image': item.product.image,
                'description': item.product.description,
                'category': item.product.category,
                'shortDescription': item.product.shortDescription,
                'sellerIds': item.product.sellerIds ?? <String>[],
                // keep legacy singular key for old queries still using sellerId
                'sellerId': (item.product.sellerIds != null &&
                        item.product.sellerIds!.isNotEmpty)
                    ? item.product.sellerIds!.first
                    : '',
              },
            )
            .toList(),

        'totalAmount': order.totalAmount,
        'orderDate': Timestamp.fromDate(order.orderDate),
        'status': order.status,
        'checkoutInfo': {
          'deliveryAddress': order.checkoutInfo.deliveryAddress,
          'phoneNumber': order.checkoutInfo.phoneNumber,
          'paymentMethod': order.checkoutInfo.paymentMethod,
          'notes': order.checkoutInfo.notes,
          'deliveryTime': Timestamp.fromDate(order.checkoutInfo.deliveryTime),
        },
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 1️⃣  Save under the user's personal sub-collection
      await _firestore
          .collection('users')
          .doc(order.userId)
          .collection('orders')
          .doc(order.orderId)
          .set(orderData);

      // 2️⃣  Save to the global orders collection (seller + admin views)
      await ordersCollection.doc(order.orderId).set(orderData);

      print('✅ Order saved successfully. sellerIds: $allSellerIds');
    } catch (e) {
      print('❌ Error saving order: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GET USER ORDERS  (customer order history)
  //  Reads from the user's personal sub-collection — fast, no composite index
  // ══════════════════════════════════════════════════════════════════════════
  Stream<List<Orders>> getUserOrders(String userId) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => _orderFromMap(doc.id, doc.data()))
              .toList());
    } catch (e) {
      print('❌ Error getting user orders: $e');
      return Stream.value([]);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GET ALL ORDERS  (admin view)
  // ══════════════════════════════════════════════════════════════════════════
  Stream<List<Orders>> getAllOrders() {
    return ordersCollection
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                _orderFromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GET SELLER ORDERS  (seller dashboard)
  //  FIX 3 — queries the top-level 'sellerIds' array (arrayContains on a
  //           nested map field never works in Firestore).
  //  Sorting is done in Dart — avoids needing a composite index.
  // ══════════════════════════════════════════════════════════════════════════
  Stream<List<Orders>> getSellerOrders(String sellerId) {
    return _firestore
        .collection('orders')
        .where('sellerIds', arrayContains: sellerId) // ✅ top-level field
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;

      // Sort newest-first in Dart (no Firestore composite index needed)
      docs.sort((a, b) {
        final aTs =
            (a.data()['orderDate'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final bTs =
            (b.data()['orderDate'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return bTs.compareTo(aTs);
      });

      return docs.map((doc) => _orderFromMap(doc.id, doc.data())).toList();
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  UPDATE ORDER STATUS  (seller dashboard — confirm / prepare / deliver)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await ordersCollection.doc(orderId).update({'status': status});
      print('✅ Order $orderId status → $status');
    } catch (e) {
      print('❌ Error updating order status: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PRODUCTS
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> saveProduct(Product product) async {
    try {
      await productsCollection.doc(product.id).set({
        'id': product.id,
        'name': product.name,
        'image': product.image,
        'price': product.price,
        'description': product.description,
        'category': product.category,
        'shortDescription': product.shortDescription,
        'sellerIds': product.sellerIds ?? <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Product saved: ${product.name}');
    } catch (e) {
      print('❌ Error saving product: $e');
      rethrow;
    }
  }

  Stream<List<Product>> getProducts() {
    return productsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return Product(
          id: data['id']?.toString() ?? '',
          name: data['name']?.toString() ?? '',
          image: data['image']?.toString() ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          description: data['description']?.toString() ?? '',
          category: data['category']?.toString() ?? '',
          shortDescription: data['shortDescription']?.toString() ?? '',
          sellerIds: data['sellerIds'] is List
              ? (data['sellerIds'] as List).map((v) => v.toString()).toList()
              : null,
        );
      }).toList();
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  USER MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await usersCollection.doc(userId).set(data, SetOptions(merge: true));
      print('✅ User data updated: $userId');
    } catch (e) {
      print('❌ Error updating user data: $e');
      rethrow;
    }
  }

  Future<int> getUserOrdersCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting user orders count: $e');
      return 0;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CONNECTION TEST
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> testFirestoreConnection() async {
    try {
      print('🧪 Testing Firestore connection...');
      final testSnapshot = await ordersCollection.limit(1).get();
      print('✅ Connection OK — orders docs: ${testSnapshot.docs.length}');

      final testDoc = ordersCollection.doc('test_connection');
      await testDoc
          .set({'test': true, 'timestamp': FieldValue.serverTimestamp()});
      await testDoc.delete();
      print('✅ Write/delete permissions OK');
    } catch (e) {
      print('❌ Firestore connection failed: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LEGACY ALIAS
  // ══════════════════════════════════════════════════════════════════════════
  Stream<List<Orders>> getOrdersLegacy(String userId) => getUserOrders(userId);

  // ══════════════════════════════════════════════════════════════════════════
  //  PRIVATE HELPER — deserialise a Firestore map into an Orders object
  //  Handles both 'sellerIds' (List) and legacy 'sellerId' (String) per item
  // ══════════════════════════════════════════════════════════════════════════
  Orders _orderFromMap(String docId, Map<String, dynamic> data) {
    // ── Reconstruct items ──────────────────────────────────────────────────
    final List<dynamic> rawItems = data['items'] as List<dynamic>? ?? [];
    final List<CartItem> items = rawItems.map((raw) {
      final m = raw as Map<String, dynamic>;

      // Support both new 'sellerIds' list and old 'sellerId' string
      List<String> sellerIds = [];
      if (m['sellerIds'] is List) {
        sellerIds = (m['sellerIds'] as List).map((v) => v.toString()).toList();
      } else if (m['sellerId'] != null && m['sellerId'].toString().isNotEmpty) {
        sellerIds = [m['sellerId'].toString()];
      }

      return CartItem(
        product: Product(
          id: m['productId']?.toString() ?? '',
          name: m['productName']?.toString() ?? '',
          image: m['image']?.toString() ?? '',
          price: (m['price'] as num?)?.toDouble() ?? 0.0,
          description: m['description']?.toString() ?? '',
          category: m['category']?.toString() ?? '',
          shortDescription: m['shortDescription']?.toString() ?? '',
          sellerIds: sellerIds.isNotEmpty ? sellerIds : null,
        ),
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
      );
    }).toList();

    // ── Reconstruct CheckoutInfo ───────────────────────────────────────────
    final Map<String, dynamic> ci =
        data['checkoutInfo'] as Map<String, dynamic>? ?? {};
    final CheckoutInfo checkoutInfo = CheckoutInfo(
      deliveryAddress: ci['deliveryAddress']?.toString() ?? '',
      phoneNumber: ci['phoneNumber']?.toString() ?? '',
      paymentMethod: ci['paymentMethod']?.toString() ?? 'Cash on Delivery',
      notes: ci['notes']?.toString(),
      deliveryTime: ci['deliveryTime'] != null
          ? (ci['deliveryTime'] as Timestamp).toDate()
          : DateTime.now(),
    );

    return Orders(
      orderId: data['orderId']?.toString() ?? docId,
      items: items,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      orderDate: data['orderDate'] != null
          ? (data['orderDate'] as Timestamp).toDate()
          : DateTime.now(),
      status: data['status']?.toString() ?? 'Pending',
      checkoutInfo: checkoutInfo,
      userId: data['userId']?.toString(),
      userEmail: data['userEmail']?.toString(),
      userName: data['userName']?.toString(),
    );
  }
}
