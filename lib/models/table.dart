/// Trạng thái của một bàn.
enum TableStatus {
  available,  // Bàn trống
  occupied,   // Đang phục vụ
  reserved;   // Đã đặt trước

  String get displayName => switch (this) {
        TableStatus.available => 'Trống',
        TableStatus.occupied  => 'Đang phục vụ',
        TableStatus.reserved  => 'Đã đặt',
      };

  static TableStatus fromString(String value) =>
      TableStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TableStatus.available,
      );
}

/// Đặt tên [CoffeeTable] để tránh conflict với [Table] widget của Flutter.
class CoffeeTable {
  final String id;
  final int tableNumber;
  final int capacity;
  final TableStatus status;
  final String? currentOrderId;

  const CoffeeTable({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    this.status = TableStatus.available,
    this.currentOrderId,
  });

  factory CoffeeTable.fromJson(Map<String, dynamic> json) => CoffeeTable(
        id: json['id'] as String,
        tableNumber: json['table_number'] as int,
        capacity: json['capacity'] as int,
        status: TableStatus.fromString(json['status'] as String? ?? 'available'),
        currentOrderId: json['current_order_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'table_number': tableNumber,
        'capacity': capacity,
        'status': status.name,
        if (currentOrderId != null) 'current_order_id': currentOrderId,
      };

  CoffeeTable copyWith({
    TableStatus? status,
    String? currentOrderId,
  }) =>
      CoffeeTable(
        id: id,
        tableNumber: tableNumber,
        capacity: capacity,
        status: status ?? this.status,
        currentOrderId: currentOrderId ?? this.currentOrderId,
      );
}
