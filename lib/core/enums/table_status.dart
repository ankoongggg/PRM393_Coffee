enum TableStatus {
  available,   // Bàn trống
  occupied,    // Đang phục vụ
  reserved;    // Đã đặt trước

  String get displayName {
    switch (this) {
      case TableStatus.available:
        return 'Trống';
      case TableStatus.occupied:
        return 'Đang phục vụ';
      case TableStatus.reserved:
        return 'Đã đặt';
    }
  }
}
