import '../core/enums/order_status.dart';
import 'order_item_model.dart';

class OrderModel {
  final String id;
  final String tableId;
  final int tableNumber;
  final String waiterId;
  final String waiterName;
  final List<OrderItemModel> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double totalAmount;

  const OrderModel({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.waiterId,
    required this.waiterName,
    required this.items,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.completedAt,
    required this.totalAmount,
  });
}
