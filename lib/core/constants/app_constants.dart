class AppConstants {
  // App info
  static const String appName = 'PRM393 Coffee';
  static const String appVersion = '1.0.0';

  // Route names
  static const String routeLogin = '/login';
  static const String routeManagerDashboard = '/manager';
  static const String routeManagerMenu = '/manager/menu';
  static const String routeManagerMenuAdd = '/manager/menu/add';
  static const String routeManagerMenuEdit = '/manager/menu/edit';
  static const String routeManagerTable = '/manager/tables';
  static const String routeManagerOrders = '/manager/orders';
  static const String routeManagerOrderDetail = '/manager/orders/detail';
  static const String routeManagerReport = '/manager/report';

  static const String routeWaiterDashboard = '/waiter';
  static const String routeWaiterTables = '/waiter/tables';
  static const String routeWaiterCreateOrder = '/waiter/order/create';
  static const String routeWaiterOrderTracking = '/waiter/order/tracking';

  static const String routeBaristaDashboard = '/barista';
  static const String routeBaristaOrderQueue = '/barista/queue';

  // Shared preferences keys
  static const String prefUserId = 'user_id';
  static const String prefUserRole = 'user_role';
}
