import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../core/enums/order_status.dart';
import '../services/firebase_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _orderSubscription;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get error => _error;

  OrderProvider() {
    startOrderListener();
  }

  void startOrderListener() {
    _orderSubscription?.cancel();
    _setLoading(true);

    _orderSubscription = _firebaseService.getOrdersStream().listen(
          (newList) {
        _orders = newList;
        _error = null;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _error = 'Lỗi stream order: $e';
        _setLoading(false);
        notifyListeners();
      },
    );
  }

  // --- QUERIES ---
  List<OrderModel> ordersByTable(String tableId) {
    return _orders.where((o) => o.tableId == tableId).toList();
  }

  List<OrderModel> get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.pending).toList();

  List<OrderModel> get preparingOrders =>
      _orders.where((o) => o.status == OrderStatus.preparing).toList();

  // --- CREATE & UPDATE ---

  Future<bool> addItemsToExistingOrder({
    required String orderId,
    required List<OrderItemModel> newItems,
  }) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) return false;

      List<dynamic> currentItemsRaw = List.from(doc.data()?['items'] ?? []);
      double currentTotal = (doc.data()?['totalAmount'] ?? 0).toDouble();

      final batchId = 'add_${DateTime.now().millisecondsSinceEpoch}';

      for (var newItem in newItems) {
        final itemWithBatch = OrderItemModel(
          menuItemId: newItem.menuItemId,
          menuItemName: newItem.menuItemName,
          unitPrice: newItem.unitPrice,
          quantity: newItem.quantity,
          note: newItem.note,
          isDone: newItem.isDone,
          batchId: batchId,
        );
        currentItemsRaw.add(itemWithBatch.toMap());
        currentTotal += (itemWithBatch.unitPrice * itemWithBatch.quantity);
      }

      await _firestore.collection('orders').doc(orderId).update({
        'items': currentItemsRaw,
        'totalAmount': currentTotal,
        'updatedAt': FieldValue.serverTimestamp(),
        'batchStatus.$batchId': 'pending',
        'status': 'pending',
      });
      return true;
    } catch (e) {
      print('❌ Lỗi thêm món: $e');
      return false;
    }
  }

  Future<String?> createOrder({
    required String tableId,
    required int tableNumber,
    required String waiterId,
    required String waiterName,
    required List<OrderItemModel> items,
    required double totalAmount,
  }) async {
    try {
      final orderId = await _firebaseService.createOrder(
        tableId: tableId,
        tableNumber: tableNumber,
        waiterId: waiterId,
        waiterName: waiterName,
        items: items,
        totalAmount: totalAmount,
      );
      return orderId;
    } catch (e) {
      _error = 'Lỗi tạo order: $e';
      return null;
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      print('--- Bắt đầu cập nhật trạng thái: $newStatus ---');
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.toString().split('.').last,
      });

      // ✅ Phải khớp chính xác với Enum của bạn (thường là OrderStatus.completed)
      if (newStatus == OrderStatus.completed) {
        print('🚀 Kích hoạt trừ kho cho đơn: $orderId');
        await _deductInventory(orderId);
      }
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi updateOrderStatus: $e');
      throw Exception('Lỗi khi cập nhật trạng thái đơn hàng: $e');
    }
  }

  Future<void> _deductInventory(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;

      final List items = orderDoc.data()?['items'] ?? [];

      for (var itemData in items) {
        final String menuItemId = itemData['menuItemId'];
        final int quantityOrdered = itemData['quantity']; // Số lượng khách mua

        final menuRef = _firestore.collection('menuItems').doc(menuItemId);

        // --- BƯỚC MỚI: TRỪ TRỰC TIẾP QUANTITY CỦA MÓN ĂN (Cái số 50 của bạn) ---
        await _firestore.runTransaction((transaction) async {
          final menuSnap = await transaction.get(menuRef);
          if (menuSnap.exists) {
            // Lấy quantity hiện tại (kiểu num để an toàn)
            final currentQty = (menuSnap.data()?['quantity'] as num?)?.toInt() ?? 0;
            final newQty = (currentQty - quantityOrdered) > 0 ? (currentQty - quantityOrdered) : 0;

            transaction.update(menuRef, {'quantity': newQty});
            print('📉 Món $menuItemId: $currentQty -> $newQty');
          }
        });

        // --- BƯỚC CŨ: TRỪ NGUYÊN LIỆU TRONG KHO (Giữ nguyên logic của bạn) ---
        final menuDoc = await menuRef.get();
        if (menuDoc.exists && menuDoc.data()!.containsKey('recipe')) {
          final recipe = Map<String, dynamic>.from(menuDoc.data()!['recipe']);
          for (var entry in recipe.entries) {
            final String ingredientId = entry.key;
            final double dosage = (entry.value as num).toDouble();
            final double qtyNeeded = dosage * quantityOrdered;

            final ingRef = _firestore.collection('ingredients').doc(ingredientId);
            await _firestore.runTransaction((transaction) async {
              final snapshot = await transaction.get(ingRef);
              if (snapshot.exists) {
                final currentStock = (snapshot.data()?['stock'] as num?)?.toDouble() ?? 0;
                final newStock = (currentStock - qtyNeeded) > 0 ? (currentStock - qtyNeeded) : 0.0;
                transaction.update(ingRef, {'stock': newStock});
              }
            });
          }
        }
      }
      print('✅ Đã trừ xong cả món ăn và nguyên liệu!');
    } catch (e) {
      print('❌ Lỗi trừ kho: $e');
    }
  }

  Future<void> updateOrderBatchStatus({
    required String orderId,
    required String batchId,
    required OrderStatus status,
  }) async {
    try {
      final statusString = status.toString().split('.').last;
      await _firebaseService.updateOrderBatchStatus(
        orderId: orderId,
        batchId: batchId,
        status: statusString,
      );
    } catch (e) {
      _error = 'Lỗi cập nhật trạng thái card: $e';
    }
  }

  Future<void> updateOrderItems(String orderId, List<OrderItemModel> items) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'items': items.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      print("❌ Lỗi cập nhật món: $e");
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _firebaseService.updateOrderStatus(orderId, 'cancelled');
    } catch (e) {
      _error = 'Lỗi hủy đơn: $e';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }
}