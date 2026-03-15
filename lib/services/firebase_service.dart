import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/table_model.dart';
import '../models/menu_item_model.dart';
import '../core/enums/order_status.dart';
import '../core/enums/table_status.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  // ─────────────────────────────────────────────────────────────
  // Orders
  // ─────────────────────────────────────────────────────────────

  Future<List<OrderModel>> fetchAllOrders() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      return snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<OrderModel>> fetchOrdersByTable(String tableId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('tableId', isEqualTo: tableId)
          .get();
      return snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<OrderModel>> fetchPendingOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String> createOrder({
    required String tableId,
    required int tableNumber,
    required String waiterId,
    required String waiterName,
    required List<OrderItemModel> items,
    required double totalAmount,
  }) async {
    try {
      final docRef = await _firestore.collection('orders').add({
        'tableId': tableId,
        'tableNumber': tableNumber,
        'waiterId': waiterId,
        'waiterName': waiterName,
        'items': items
            .map((item) => {
          'menuItemId': item.menuItemId,
          'menuItemName': item.menuItemName,
          'unitPrice': item.unitPrice,
          'quantity': item.quantity,
          'note': item.note,
        })
            .toList(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'totalAmount': totalAmount,
      });
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        if (status == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderItems(String orderId, List<OrderItemModel> newItems, double newTotal) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'items': newItems.map((item) => {
          'menuItemId': item.menuItemId,
          'menuItemName': item.menuItemName,
          'unitPrice': item.unitPrice,
          'quantity': item.quantity,
          'note': item.note,
        }).toList(),
        'totalAmount': newTotal,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Lỗi cập nhật đơn hàng: $e');
      rethrow;
    }
  }

  Stream<List<OrderModel>> getOrdersStream() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList());
  }

  // ─────────────────────────────────────────────────────────────
  // Menu Items
  // ─────────────────────────────────────────────────────────────

  Future<List<MenuItemModel>> fetchAllMenuItems() async {
    try {
      final snapshot = await _firestore.collection('menuItems').get();
      return snapshot.docs.map((doc) => _menuItemFromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<MenuItemModel>> getMenuItemsStream() {
    return _firestore
        .collection('menuItems')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => _menuItemFromFirestore(doc)).toList());
  }

  Future<List<MenuItemModel>> fetchAvailableMenuItems() async {
    try {
      final snapshot = await _firestore
          .collection('menuItems')
          .where('isAvailable', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) => _menuItemFromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addMenuItem(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('menuItems').add(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('menuItems').doc(id).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String id) async {
    try {
      await _firestore.collection('menuItems').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Tables
  // ─────────────────────────────────────────────────────────────

  Future<List<TableModel>> fetchAllTables() async {
    try {
      final snapshot = await _firestore.collection('tables').get();
      return snapshot.docs.map((doc) => _tableFromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<TableModel>> getTablesStream() {
    return _firestore.collection('tables').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => _tableFromFirestore(doc)).toList());
  }

  Future<void> updateTableStatus(String tableId, String status,
      {String? currentOrderId}) async {
    try {
      await _firestore.collection('tables').doc(tableId).update({
        'status': status,
        'currentOrderId': currentOrderId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addTable(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('tables').add(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTable(String tableId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('tables').doc(tableId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTable(String tableId) async {
    try {
      await _firestore.collection('tables').doc(tableId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  OrderModel _orderFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    List<OrderItemModel> items = [];
    if (data['items'] is List) {
      items = (data['items'] as List)
          .map((item) => OrderItemModel(
        menuItemId: item['menuItemId'] ?? '',
        menuItemName: item['menuItemName'] ?? '',
        unitPrice: (item['unitPrice'] ?? 0).toDouble(),
        quantity: item['quantity'] ?? 1,
        note: item['note'],
      ))
          .toList();
    }

    OrderStatus status = OrderStatus.pending;
    try {
      status = OrderStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      );
    } catch (_) {}

    return OrderModel(
      id: doc.id,
      tableId: data['tableId'] ?? '',
      tableNumber: data['tableNumber'] ?? 0,
      waiterId: data['waiterId'] ?? '',
      waiterName: data['waiterName'] ?? '',
      items: items,
      status: status,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
    );
  }

  TableModel _tableFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    TableStatus status = TableStatus.available;
    try {
      status = TableStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
        orElse: () => TableStatus.available,
      );
    } catch (_) {}

    return TableModel(
      id: doc.id,
      tableNumber: data['tableNumber'] ?? 0,
      capacity: data['capacity'] ?? 2,
      status: status,
      currentOrderId: data['currentOrderId'],
    );
  }

  MenuItemModel _menuItemFromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    double priceValue = 0;

    if (data['price'] != null) {
      if (data['price'] is String) {
        priceValue = double.tryParse(data['price']) ?? 0;
      } else if (data['price'] is num) {
        priceValue = (data['price'] as num).toDouble();
      }
    }

    return MenuItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: priceValue,
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
    );
  }
}