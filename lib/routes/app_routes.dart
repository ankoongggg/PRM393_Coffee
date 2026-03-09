/// Tập trung toàn bộ route string của ứng dụng.
///
/// Convention:
///   - Dùng dấu `/` phân cấp theo role: `/manager/...`, `/waiter/...`, `/barista/...`
///   - Tên hằng = camelCase mô tả màn hình đích
///
/// Dùng trong Navigator:
/// ```dart
/// Navigator.pushNamed(context, AppRoutes.managerMenu);
/// ```
abstract final class AppRoutes {
  // ── Auth ──────────────────────────────────────────────────────
  static const String login = '/login';

  // ── Manager ───────────────────────────────────────────────────
  static const String managerDashboard = '/manager/dashboard';
  static const String managerMenu      = '/manager/menu';
  static const String managerMenuAdd   = '/manager/menu/add';
  static const String managerMenuEdit  = '/manager/menu/edit';
  static const String managerTables    = '/manager/tables';
  static const String managerOrders    = '/manager/orders';
  static const String managerOrderDetail = '/manager/orders/detail';
  static const String managerRevenue   = '/manager/revenue';
  static const String managerAccounts  = '/manager/accounts';

  // ── Waiter ────────────────────────────────────────────────────
  static const String waiterDashboard  = '/waiter/dashboard';
  static const String waiterTables     = '/waiter/tables';
  static const String waiterCreateOrder = '/waiter/create-order';
  static const String waiterOrders     = '/waiter/orders';

  // ── Barista ───────────────────────────────────────────────────
  static const String baristaDashboard = '/barista/dashboard';
  static const String baristaOrders    = '/barista/orders';
}
