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

  // Getters
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

  // ─────────────────────────────────────────────────────────────
  // QUERIES (Sửa lỗi thiếu method ordersByTable)
  // ─────────────────────────────────────────────────────────────

  /// ✅ Lấy danh sách đơn hàng của một bàn cụ thể
  List<OrderModel> ordersByTable(String tableId) {
    return _orders.where((o) => o.tableId == tableId).toList();
  }

  // Barista: lọc order theo trạng thái
  List<OrderModel> get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.pending).toList();

  List<OrderModel> get preparingOrders =>
      _orders.where((o) => o.status == OrderStatus.preparing).toList();

  // ─────────────────────────────────────────────────────────────
  // CREATE & UPDATE ORDERS
  // ─────────────────────────────────────────────────────────────

  /// ✅ Thêm món vào đơn hàng hiện có (Cộng dồn)
  Future<bool> addItemsToExistingOrder({
    required String orderId,
    required List<OrderItemModel> newItems,
  }) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) return false;

      List<dynamic> currentItemsRaw = List.from(doc.data()?['items'] ?? []);
      double currentTotal = (doc.data()?['totalAmount'] ?? 0).toDouble();

      for (var newItem in newItems) {
        // ✅ Không cộng dồn vào món đã "isDone: true"
        // Chúng ta cứ add mới vào list để Barista thấy món mới cần pha
        currentItemsRaw.add(newItem.toMap());
        currentTotal += (newItem.unitPrice * newItem.quantity);
      }

      await _firestore.collection('orders').doc(orderId).update({
        'items': currentItemsRaw,
        'totalAmount': currentTotal,
        'updatedAt': FieldValue.serverTimestamp(),
        // Giữ nguyên status của Order, không kéo về 'pending' nữa
      });

      return true;
    } catch (e) {
      print('❌ Lỗi: $e');
      return false;
    }
  }

  /// Tạo order mới hoàn toàn
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

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final statusString = status.toString().split('.').last;
      await _firebaseService.updateOrderStatus(orderId, statusString);
    } catch (e) {
      _error = 'Lỗi cập nhật trạng thái: $e';
    }
  }

  Future<void> updateOrderItems(String orderId, List<OrderItemModel> items) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'items': items.map((e) => e.toMap()).toList(),
      });
      // Không cần notifyListeners vì stream sẽ tự cập nhật dữ liệu mới
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

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

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