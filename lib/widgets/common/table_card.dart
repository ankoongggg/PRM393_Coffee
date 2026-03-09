// TODO: Implement TableCard
// Widget hiển thị 1 bàn dạng card/tile
// Dùng cho: Manager (table management), Waiter (chọn bàn)
//
// Manager mode: hiển thị actions edit/delete
// Waiter mode: bàn trống = tap để chọn; bàn có người = tap để xem order

import 'package:flutter/material.dart';
import '../../models/table_model.dart';

class TableCard extends StatelessWidget {
  final TableModel table;
  final bool isManagerMode;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;   // Manager
  final VoidCallback? onDelete; // Manager

  const TableCard({
    super.key,
    required this.table,
    this.isManagerMode = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Build card với màu nền theo TableStatus + conditional actions
    return const Placeholder();
  }
}
