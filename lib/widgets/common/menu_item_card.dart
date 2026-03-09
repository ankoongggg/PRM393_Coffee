// TODO: Implement MenuItemCard
// Widget hiển thị 1 menu item
// Dùng cho: Manager (menu list), Waiter (chọn món khi tạo order)
//
// Manager mode: hiển thị actions edit/delete + toggle availability
// Waiter mode: hiển thị nút thêm vào giỏ + số lượng

import 'package:flutter/material.dart';
import '../../models/menu_item_model.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItemModel menuItem;
  final bool isManagerMode;
  final VoidCallback? onEdit;       // Manager
  final VoidCallback? onDelete;     // Manager
  final VoidCallback? onAddToOrder; // Waiter

  const MenuItemCard({
    super.key,
    required this.menuItem,
    this.isManagerMode = false,
    this.onEdit,
    this.onDelete,
    this.onAddToOrder,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Build card UI với conditional actions
    return const Placeholder();
  }
}
