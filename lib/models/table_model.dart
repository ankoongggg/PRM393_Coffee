import '../core/enums/table_status.dart';

class TableModel {
  final String id;
  final int tableNumber;
  final int capacity;
  final TableStatus status;
  final String? currentOrderId;

  const TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    this.status = TableStatus.available,
    this.currentOrderId,
  });
}
