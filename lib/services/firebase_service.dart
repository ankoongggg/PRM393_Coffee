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

  /// Lấy tất cả orders từ Firestore
  Future<List<OrderModel>> fetchAllOrders() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      return snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Lỗi fetch orders: $e');
      return [];
    }
  }

  /// Lấy orders của 1 bàn
  Future<List<OrderModel>> fetchOrdersByTable(String tableId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('tableId', isEqualTo: tableId)
          .get();
      return snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Lỗi fetch orders by table: $e');
      return [];
    }
  }

  /// Lấy orders đang chờ xử lý (pending)
  Future<List<OrderModel>> fetchPendingOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Lỗi fetch pending orders: $e');
      return [];
    }
  }

  /// Lấy orders đang pha chế (preparing)
  Future<List<OrderModel>> fetchPreparingOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'preparing')
          .get();
      return snapshot.docs.map((doc) => _orderFromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Lỗi fetch preparing orders: $e');
      return [];
    }
  }

  /// Tạo order mới
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
      print('✅ Order tạo thành công: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Lỗi tạo order: $e');
      rethrow;
    }
  }

  /// Cập nhật trạng thái order
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        if (status == 'completed')
          'completedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Cập nhật order $orderId thành $status');
    } catch (e) {
      print('❌ Lỗi cập nhật order: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Menu Items
  // ─────────────────────────────────────────────────────────────

  /// Lấy tất cả menu items
  Future<List<MenuItemModel>> fetchAllMenuItems() async {
    try {
      print('🔍 Bắt đầu fetch menuItems...');
      final snapshot = await _firestore.collection('menuItems').get();
      print('✅ Fetch ${snapshot.docs.length} menu items từ Firestore');
      
      for (var doc in snapshot.docs) {
        print('📍 MenuItem - ID: ${doc.id}, Name: ${doc['name']}');
      }
      
      return snapshot.docs.map((doc) => _menuItemFromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Lỗi fetch menu items: $e');
      return [];
    }
  }

  /// Lấy menu items có sẵn (isAvailable = true)
  Future<List<MenuItemModel>> fetchAvailableMenuItems() async {
    try {
      final snapshot = await _firestore
          .collection('menuItems')
          .where('isAvailable', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) => _menuItemFromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Lỗi fetch available menu items: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Tables
  // ─────────────────────────────────────────────────────────────

  /// Lấy tất cả bàn
  Future<List<TableModel>> fetchAllTables() async {
    try {
      print('🔍 Bắt đầu fetch tables...');
      print('📍 Database app: ${_firestore.app.name}');
      print('📍 Collection name: tables');
      
      final snapshot = await _firestore.collection('tables').get();
      print('✅ Fetch ${snapshot.docs.length} documents từ collection tables');
      
      if (snapshot.docs.isEmpty) {
        print('⚠️ Collection tables trống! Kiểm tra Firestore Console');
      }
      
      // Debug: kiểm tra dữ liệu chi tiết
      for (var doc in snapshot.docs) {
        print('📍 Bàn - ID: ${doc.id}');
        print('   Data: ${doc.data()}');
      }
      
      final tables = snapshot.docs.map((doc) => _tableFromFirestore(doc)).toList();
      print('✅ Convert thành ${tables.length} TableModel');
      
      // List all table numbers
      if (tables.isNotEmpty) {
        final tableNumbers = tables.map((t) => t.tableNumber).toList();
        print('📋 Table numbers: $tableNumbers');
      }
      
      return tables;
    } catch (e) {
      print('❌ Lỗi fetch tables: $e');
      print('🔧 Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Lấy bàn trống (available)
  Future<List<TableModel>> fetchAvailableTables() async {
    try {
      final snapshot = await _firestore
          .collection('tables')
          .where('status', isEqualTo: 'available')
          .get();
      return snapshot.docs.map((doc) => _tableFromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Lỗi fetch available tables: $e');
      return [];
    }
  }

  /// Cập nhật trạng thái bàn
  Future<void> updateTableStatus(
    String tableId,
    String status, {
    String? currentOrderId,
  }) async {
    try {
      await _firestore.collection('tables').doc(tableId).update({
        'status': status,
        'currentOrderId': currentOrderId,
      });
      print('✅ Cập nhật bàn $tableId: $status');
    } catch (e) {
      print('❌ Lỗi cập nhật bàn: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers - Convert Firestore Document → Models
  // ─────────────────────────────────────────────────────────────

  OrderModel _orderFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    // Convert items array
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

    // Convert status string to enum
    OrderStatus status = OrderStatus.pending;
    try {
      status = OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      );
    } catch (e) {
      print('⚠️ Status không hợp lệ: ${data['status']}');
    }

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

    // Convert status string to enum
    TableStatus status = TableStatus.available;
    try {
      status = TableStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => TableStatus.available,
      );
    } catch (e) {
      print('⚠️ Table status không hợp lệ: ${data['status']}');
    }

    return TableModel(
      id: doc.id,
      tableNumber: data['tableNumber'] ?? 0,
      capacity: data['capacity'] ?? 2,
      status: status,
      currentOrderId: data['currentOrderId'],
    );
  }

  MenuItemModel _menuItemFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return MenuItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageURL'] ?? data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
    );
  }
}
