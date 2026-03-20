import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/table_model.dart';
import '../models/menu_item_model.dart';
import '../core/enums/order_status.dart';
import '../core/enums/table_status.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

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
      final batchIds = items
          .map((i) => i.batchId.isEmpty ? 'initial' : i.batchId)
          .toSet()
          .toList();
      if (batchIds.isEmpty) batchIds.add('initial');
      final batchStatus = <String, String>{
        for (final b in batchIds) b: 'pending',
      };

      final docRef = await _firestore.collection('orders').add({
        'tableId': tableId,
        'tableNumber': tableNumber,
        'waiterId': waiterId,
        'waiterName': waiterName,
        'items': items
            .map((item) => OrderItemModel(
                  menuItemId: item.menuItemId,
                  menuItemName: item.menuItemName,
                  unitPrice: item.unitPrice,
                  quantity: item.quantity,
                  note: item.note,
                  isDone: item.isDone,
                  batchId: item.batchId,
                ).toMap())
            .toList(),
        'batchStatus': batchStatus,
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
      // Guard: không cho hủy khi đơn đã hoàn thành/đã phục vụ
      if (status == 'cancelled') {
        final snap = await _firestore.collection('orders').doc(orderId).get();
        final currentStatus = snap.data()?['status'] as String?;
        if (currentStatus == 'completed' || currentStatus == 'served') {
          throw Exception('Không thể hủy đơn khi đã hoàn thành/đã phục vụ');
        }
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        if (status == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderBatchStatus({
    required String orderId,
    required String batchId,
    required String status,
  }) async {
    await _firestore.runTransaction((tx) async {
      final ref = _firestore.collection('orders').doc(orderId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final currentOrderStatus = data['status'] as String?;
      if (currentOrderStatus == 'cancelled' || currentOrderStatus == 'served') {
        return;
      }

      final currentBatchStatusRaw = (data['batchStatus'] as Map?)?.cast<String, dynamic>() ?? {};
      final updatedBatchStatus = <String, String>{
        for (final e in currentBatchStatusRaw.entries)
          e.key: (e.value ?? 'pending').toString(),
      };
      final b = batchId.isEmpty ? 'initial' : batchId;
      updatedBatchStatus[b] = status;

      // Recompute overall order status from batches
      String overall = 'completed';
      if (updatedBatchStatus.values.any((s) => s == 'pending')) {
        overall = 'pending';
      } else if (updatedBatchStatus.values.any((s) => s == 'preparing')) {
        overall = 'preparing';
      }

      tx.update(ref, {
        'batchStatus': updatedBatchStatus,
        'status': overall,
        if (overall == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateOrderItems(String orderId, List<OrderItemModel> newItems, double newTotal) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'items': newItems.map((item) => item.toMap()).toList(),
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

  Future<String> uploadMenuItemImageBytes({
    required List<int> bytes,
    required String fileExt,
  }) async {
    final safeExt = fileExt.isEmpty ? 'jpg' : fileExt.toLowerCase();
    final fileName = 'menu_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    final ref = _storage.ref().child('menu_images/$fileName');
    final contentType = switch (safeExt) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'application/octet-stream',
    };
    final meta = SettableMetadata(contentType: contentType);
    final task = await ref.putData(Uint8List.fromList(bytes), meta);
    return await task.ref.getDownloadURL();
  }

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

  // Trong firebase_service.dart
  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      // ✅ Phải là 'menuItems' cho đồng bộ với Database của bạn
      await _firestore.collection('menuItems').doc(id).update(data);
      print("✅ Đã cập nhật thành công vào collection menuItems");
    } catch (e) {
      print("❌ Lỗi update Firebase: $e");
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
          .whereType<Map<String, dynamic>>()
          .map((item) => OrderItemModel.fromMap(item))
          .toList();
    }

    OrderStatus status = OrderStatus.pending;
    try {
      status = OrderStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      );
    } catch (_) {}

    Map<String, OrderStatus> batchStatus = {};
    final raw = data['batchStatus'];
    if (raw is Map) {
      for (final e in raw.entries) {
        final key = e.key?.toString() ?? 'initial';
        final val = e.value?.toString() ?? 'pending';
        try {
          batchStatus[key] = OrderStatus.values.firstWhere(
            (s) => s.toString().split('.').last == val,
            orElse: () => status,
          );
        } catch (_) {
          batchStatus[key] = status;
        }
      }
    }
    // Backward compatibility: nếu order cũ chưa có batchStatus thì khởi tạo theo status hiện tại
    if (batchStatus.isEmpty) {
      final batchIds = items
          .map((i) => i.batchId.isEmpty ? 'initial' : i.batchId)
          .toSet()
          .toList();
      if (batchIds.isEmpty) batchIds.add('initial');
      batchStatus = {for (final b in batchIds) b: status};
    }

    return OrderModel(
      id: doc.id,
      tableId: data['tableId'] ?? '',
      tableNumber: data['tableNumber'] ?? 0,
      waiterId: data['waiterId'] ?? '',
      waiterName: data['waiterName'] ?? '',
      items: items,
      status: status,
      batchStatus: batchStatus,
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
      // ✅ ĐỔI THÀNH imageURL (viết hoa) để khớp với Model mới
      imageURL: (data['imageURL'] ?? data['imageUrl'] ?? data['image_url'] ?? '').toString(),
      category: data['category'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      // ✅ Bổ sung quantity và recipe để tránh lỗi thiếu tham số nếu Model yêu cầu
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      recipe: data['recipe'] != null ? Map<String, dynamic>.from(data['recipe']) : null,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Users / Accounts
  // ─────────────────────────────────────────────────────────────

  /// Lấy danh sách tất cả users từ Firebase
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      // Thử lấy từ collection 'users' trước
      var snapshot = await _firestore.collection('users').get();
      
      print('DEBUG: Fetched ${snapshot.docs.length} users from "users" collection');
      
      if (snapshot.docs.isEmpty) {
        // Nếu không có, có thể tên collection khác, thử các tên khác
        print('DEBUG: "users" collection is empty, trying other names...');
      }
      
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            print('DEBUG: User document: ${doc.id} - Data: $data');
            return {
              'id': doc.id,
              'name': data['name'] ?? data['Name'] ?? '',
              'email': data['email'] ?? data['Email'] ?? '',
              'role': (data['role'] ?? data['Role'] ?? 'Waiter').toString().toLowerCase(),
              'active': data['active'] ?? data['Active'] ?? data['status'] ?? true,
            };
          })
          .toList();
    } catch (e) {
      print('ERROR fetching users: $e');
      return [];
    }
  }

  /// Lấy stream danh sách users real-time từ Firebase
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc['name'] ?? '',
                'email': doc['email'] ?? '',
                'role': doc['role'] ?? 'Waiter',
                'active': doc['active'] ?? true,
              })
          .toList();
    });
  }
}
