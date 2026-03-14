// TODO: Implement OrderProvider
// Chịu trách nhiệm: tạo order (Waiter), xử lý order (Barista), quản lý order (Manager)

import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../core/enums/order_status.dart';
import '../services/firebase_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Waiter: lọc order theo bàn
  List<OrderModel> ordersByTable(String tableId) =>
      _orders.where((o) => o.tableId == tableId).toList();

  // Barista: lọc order đang chờ/đang pha
  List<OrderModel> get pendingOrders => _orders
      .where((o) => o.status == OrderStatus.pending)
      .toList();
  List<OrderModel> get preparingOrders => _orders
      .where((o) => o.status == OrderStatus.preparing)
      .toList();

  // ─────────────────────────────────────────────────────────────
  // FETCH ORDERS
  // ─────────────────────────────────────────────────────────────

  /// Lấy tất cả orders (Manager)
  Future<void> fetchAllOrders() async {
    _setLoading(true);
    try {
      _orders = await _firebaseService.fetchAllOrders();
      _error = null;
      print('✅ Fetch ${_orders.length} orders thành công');
    } catch (e) {
      _error = 'Lỗi fetch orders: $e';
      print('❌ $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy orders của waiter
  Future<void> fetchOrdersByWaiter(String waiterId) async {
    _setLoading(true);
    try {
      final allOrders = await _firebaseService.fetchAllOrders();
      _orders = allOrders.where((o) => o.waiterId == waiterId).toList();
      _error = null;
      print('✅ Fetch ${_orders.length} orders của waiter $waiterId');
    } catch (e) {
      _error = 'Lỗi fetch orders: $e';
      print('❌ $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy pending orders (Barista - queue làm việc)
  Future<void> fetchPendingOrders() async {
    _setLoading(true);
    try {
      _orders = await _firebaseService.fetchPendingOrders();
      _error = null;
      print('✅ Fetch ${_orders.length} pending orders');
    } catch (e) {
      _error = 'Lỗi fetch pending orders: $e';
      print('❌ $_error');
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CREATE & UPDATE ORDERS
  // ─────────────────────────────────────────────────────────────

  /// Tạo order mới (Waiter)
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
      print('✅ Tạo order thành công: $orderId');
      
      // Reload orders
      await fetchAllOrders();
      return orderId;
    } catch (e) {
      _error = 'Lỗi tạo order: $e';
      print('❌ $_error');
      return null;
    }
  }

  /// Thêm món vào order (Waiter)
  Future<void> addItemToOrder(String orderId, OrderItemModel item) async {
    try {
      // TODO: Implement add item (cần update Firestore array)
      print('TODO: Add item to order');
    } catch (e) {
      _error = 'Lỗi thêm món: $e';
      print('❌ $_error');
    }
  }

  /// Cập nhật trạng thái order (Barista/Manager)
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final statusString = status.toString().split('.').last;
      await _firebaseService.updateOrderStatus(orderId, statusString);
      print('✅ Cập nhật order $orderId → $statusString');
      
      // Reload orders
      await fetchAllOrders();
    } catch (e) {
      _error = 'Lỗi cập nhật order: $e';
      print('❌ $_error');
    }
  }

  /// Xóa/Hủy order
  Future<void> cancelOrder(String orderId) async {
    try {
      await _firebaseService.updateOrderStatus(orderId, 'cancelled');
      print('✅ Hủy order: $orderId');
      
      // Reload orders
      await fetchAllOrders();
    } catch (e) {
      _error = 'Lỗi hủy order: $e';
      print('❌ $_error');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
