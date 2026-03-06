/// Trạng thái của một đơn hàng.
enum OrderStatus {
  pending,    // Chờ barista xác nhận
  preparing,  // Barista đang pha chế
  completed,  // Barista hoàn thành
  served,     // Waiter đã phục vụ cho khách
  cancelled;  // Đã hủy

  String get displayName => switch (this) {
        OrderStatus.pending   => 'Chờ xử lý',
        OrderStatus.preparing => 'Đang pha chế',
        OrderStatus.completed => 'Đã hoàn thành',
        OrderStatus.served    => 'Đã phục vụ',
        OrderStatus.cancelled => 'Đã hủy',
      };

  static OrderStatus fromString(String value) =>
      OrderStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => OrderStatus.pending,
      );
}

/// Một dòng món trong đơn hàng.
class OrderItem {
  final String menuItemId;
  final String menuItemName;
  final double unitPrice;
  final int quantity;
  final String? note;

  const OrderItem({
    required this.menuItemId,
    required this.menuItemName,
    required this.unitPrice,
    required this.quantity,
    this.note,
  });

  double get subtotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        menuItemId: json['menu_item_id'] as String,
        menuItemName: json['menu_item_name'] as String,
        unitPrice: (json['unit_price'] as num).toDouble(),
        quantity: json['quantity'] as int,
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'menu_item_id': menuItemId,
        'menu_item_name': menuItemName,
        'unit_price': unitPrice,
        'quantity': quantity,
        if (note != null) 'note': note,
      };
}

/// Đơn hàng đầy đủ.
class Order {
  final String id;
  final String tableId;
  final int tableNumber;
  final String waiterId;
  final String waiterName;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Order({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.waiterId,
    required this.waiterName,
    required this.items,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.completedAt,
  });

  double get totalAmount =>
      items.fold(0, (sum, item) => sum + item.subtotal);

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        tableId: json['table_id'] as String,
        tableNumber: json['table_number'] as int,
        waiterId: json['waiter_id'] as String,
        waiterName: json['waiter_name'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
        createdAt: DateTime.parse(json['created_at'] as String),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'table_id': tableId,
        'table_number': tableNumber,
        'waiter_id': waiterId,
        'waiter_name': waiterName,
        'items': items.map((e) => e.toJson()).toList(),
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        if (completedAt != null)
          'completed_at': completedAt!.toIso8601String(),
      };

  Order copyWith({OrderStatus? status, DateTime? completedAt}) => Order(
        id: id,
        tableId: tableId,
        tableNumber: tableNumber,
        waiterId: waiterId,
        waiterName: waiterName,
        items: items,
        status: status ?? this.status,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
      );
}
