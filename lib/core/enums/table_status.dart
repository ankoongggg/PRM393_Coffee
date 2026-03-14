enum TableStatus {
  available,   // Bàn trống
  occupied,    // Đang phục vụ
  waiting;     // Đang chờ phục vụ (order xong, chưa được phục vụ)

  String get displayName {
    switch (this) {
      case TableStatus.available:
        return 'Trống';
      case TableStatus.occupied:
        return 'Đang phục vụ';
      case TableStatus.waiting:
        return 'Chờ phục vụ';
    }
  }
}
