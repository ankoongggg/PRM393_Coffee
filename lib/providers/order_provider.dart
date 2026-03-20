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

  // ✅ Theo dõi các order đã trừ kho để tránh trừ trùng
  final Set<String> _deductedOrderIds = {};
  bool _isFirstStreamLoad = true;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get error => _error;

  OrderProvider() {
    startOrderListener();
  }

  void startOrderListener() {
    _orderSubscription?.cancel();
    _setLoading(true);
    _isFirstStreamLoad = true;

    _orderSubscription = _firebaseService.getOrdersStream().listen(
          (newList) {
        // ✅ Phát hiện order vừa chuyển sang completed để trừ kho
        _detectAndDeductCompleted(newList);

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

  /// ✅ So sánh danh sách cũ và mới, nếu order chuyển sang completed → trừ kho
  void _detectAndDeductCompleted(List<OrderModel> newList) {
    if (_isFirstStreamLoad) {
      // Lần đầu load: đánh dấu các order đã completed là đã trừ (tránh trừ lại)
      for (final order in newList) {
        if (order.status == OrderStatus.completed || order.status == OrderStatus.served) {
          _deductedOrderIds.add(order.id);
        }
      }
      _isFirstStreamLoad = false;
      return;
    }

    for (final newOrder in newList) {
      if (newOrder.status != OrderStatus.completed) continue;
      if (_deductedOrderIds.contains(newOrder.id)) continue;

      // Kiểm tra xem order này trước đó chưa completed
      final oldOrder = _orders.where((o) => o.id == newOrder.id).firstOrNull;
      final wasNotCompleted = oldOrder == null || oldOrder.status != OrderStatus.completed;

      if (wasNotCompleted) {
        _deductedOrderIds.add(newOrder.id);
        _deductInventory(newOrder.id);
        print('🏪 Auto-deduct kho cho order ${newOrder.id} (status → completed)');
      }
    }
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
      // Cập nhật trạng thái đơn hàng
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.toString().split('.').last,
      });
      // ✅ Trừ kho được xử lý tự động trong stream listener (_detectAndDeductCompleted)
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi updateOrderStatus: $e');
    }
  }

  Future<void> _deductInventory(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;

      final List items = orderDoc.data()?['items'] ?? [];

      // ✅ Bước 1: Thu thập tổng lượng cần trừ cho từng nguyên liệu
      final Map<String, double> deductions = {};

      for (var itemData in items) {
        final String menuItemId = itemData['menuItemId'];
        final int quantityOrdered = (itemData['quantity'] as num).toInt();

        final menuSnap = await _firestore.collection('menuItems').doc(menuItemId).get();
        if (menuSnap.exists && menuSnap.data()!.containsKey('recipe')) {
          final recipe = Map<String, dynamic>.from(menuSnap.data()!['recipe']);

          for (var entry in recipe.entries) {
            final String ingredientId = entry.key;
            final double dosage = (entry.value as num).toDouble();
            final double totalDeduct = dosage * quantityOrdered;
            deductions[ingredientId] = (deductions[ingredientId] ?? 0) + totalDeduct;
          }
        }
      }

      // ✅ Bước 2: Dùng Transaction để đọc-ghi atomic, đảm bảo stock KHÔNG BAO GIỜ ÂM
      for (var entry in deductions.entries) {
        final ingRef = _firestore.collection('ingredients').doc(entry.key);

        await _firestore.runTransaction((tx) async {
          final ingSnap = await tx.get(ingRef);
          if (!ingSnap.exists) return;

          final currentStock = (ingSnap.data()?['stock'] ?? 0).toDouble();
          // Trừ tối đa bằng stock hiện có, clamp về 0 nếu bị âm
          final newStock = (currentStock - entry.value).clamp(0.0, double.infinity);
          tx.update(ingRef, {'stock': newStock});
        });
      }

      // Sau khi trừ xong, thông báo cho các Provider khác load lại dữ liệu
      notifyListeners();
      print('✅ Đã thực thi trừ kho bằng Transaction thành công!');

    } catch (e) {
      print('❌ Lỗi hệ thống trừ kho: $e');
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