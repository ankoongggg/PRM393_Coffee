// TODO: Implement OrderProvider
// Chịu trách nhiệm: tạo order (Waiter), xử lý order (Barista), quản lý order (Manager)

import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../core/enums/order_status.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];

  List<OrderModel> get orders => List.unmodifiable(_orders);

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

  // TODO: fetchAllOrders() - lấy tất cả orders (Manager)
  // TODO: fetchOrdersByWaiter(String waiterId) - Waiter xem order của mình
  // TODO: fetchPendingOrders() - Barista xem queue
  // TODO: createOrder(String tableId, List<OrderItemModel> items) - Waiter tạo order
  // TODO: addItemToOrder(String orderId, OrderItemModel item) - Waiter thêm món
  // TODO: updateOrderStatus(String orderId, OrderStatus status) - Barista/Manager cập nhật trạng thái
  // TODO: cancelOrder(String orderId) - Hủy order
}
