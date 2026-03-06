// TODO: Implement StatusBadge
// Widget hiển thị badge trạng thái với màu sắc tương ứng
// Dùng cho: OrderStatus, TableStatus

import 'package:flutter/material.dart';
import '../../core/enums/order_status.dart';
import '../../core/enums/table_status.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  // TODO: Map OrderStatus → color và label

  @override
  Widget build(BuildContext context) {
    // TODO: Build colored badge chip
    return const Placeholder();
  }
}

class TableStatusBadge extends StatelessWidget {
  final TableStatus status;

  const TableStatusBadge({super.key, required this.status});

  // TODO: Map TableStatus → color và label

  @override
  Widget build(BuildContext context) {
    // TODO: Build colored badge chip
    return const Placeholder();
  }
}
