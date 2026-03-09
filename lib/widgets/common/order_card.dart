// TODO: Implement OrderCard
// Widget hiển thị thông tin tóm tắt 1 đơn hàng
// Dùng cho: Manager (order list), Waiter (tracking), Barista (queue)
//
// Hiển thị: mã đơn, số bàn, tên waiter, số món, tổng tiền, trạng thái, thời gian

import 'package:flutter/material.dart';
import '../../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final Widget? trailingAction; // action button khác nhau theo role

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Build card UI
    return const Placeholder();
  }
}
