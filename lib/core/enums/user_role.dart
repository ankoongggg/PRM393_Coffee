enum UserRole {
  manager,
  waiter,
  barista;

  String get displayName {
    switch (this) {
      case UserRole.manager:
        return 'Quản lý';
      case UserRole.waiter:
        return 'Nhân viên phục vụ';
      case UserRole.barista:
        return 'Barista';
    }
  }

  String get icon {
    switch (this) {
      case UserRole.manager:
        return '👔';
      case UserRole.waiter:
        return '🧑‍💼';
      case UserRole.barista:
        return '☕';
    }
  }
}
