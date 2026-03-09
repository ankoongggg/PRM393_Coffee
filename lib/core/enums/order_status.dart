enum OrderStatus {
  pending,      // Chờ barista xác nhận
  preparing,    // Barista đang pha chế
  completed,    // Barista hoàn thành
  served,       // Waiter đã phục vụ cho khách
  cancelled;    // Đã hủy

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Chờ xử lý';
      case OrderStatus.preparing:
        return 'Đang pha chế';
      case OrderStatus.completed:
        return 'Đã hoàn thành';
      case OrderStatus.served:
        return 'Đã phục vụ';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }
}
