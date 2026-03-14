// TODO: Implement AppRouter
// Điều hướng dựa trên UserRole sau khi đăng nhập

import 'package:flutter/material.dart';
import '../core/enums/user_role.dart';
import '../routes/app_routes.dart';
import '../screens/auth/login_screen.dart';
import '../screens/manager/manager_dashboard.dart';
import '../screens/manager/menu_management/menu_list_screen.dart';
import '../screens/manager/menu_management/add_edit_menu_item_screen.dart';
import '../screens/manager/table_management/table_management_screen.dart';
import '../screens/manager/order_management/order_list_screen.dart';
import '../screens/manager/order_management/order_detail_screen.dart';
import '../screens/manager/report/report_screen.dart';
import '../screens/manager/account_management_screen.dart';
import '../screens/waiter/waiter_dashboard.dart';
import '../screens/waiter/table/table_list_screen.dart';
import '../screens/waiter/order/create_order_screen.dart';
import '../screens/waiter/order/cart_detail_screen.dart';
import '../screens/waiter/order/order_tracking_screen.dart';
import '../screens/barista/barista_dashboard.dart';
import '../screens/barista/order_queue_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // ── Manager ──────────────────────────────────────────────
      case AppRoutes.managerDashboard:
        return MaterialPageRoute(builder: (_) => const ManagerDashboard());
      case AppRoutes.managerMenu:
        return MaterialPageRoute(builder: (_) => const MenuListScreen());
      case AppRoutes.managerMenuAdd:
        return MaterialPageRoute(builder: (_) => const AddEditMenuItemScreen());
      case AppRoutes.managerMenuEdit:
        return MaterialPageRoute(builder: (_) => const AddEditMenuItemScreen());
      case AppRoutes.managerTables:
        return MaterialPageRoute(builder: (_) => const TableManagementScreen());
      case AppRoutes.managerOrders:
        return MaterialPageRoute(builder: (_) => const OrderListScreen());
      case AppRoutes.managerOrderDetail:
        final orderId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: orderId),
        );
      case AppRoutes.managerRevenue:
        return MaterialPageRoute(builder: (_) => const ReportScreen());
      case AppRoutes.managerAccounts:
        return MaterialPageRoute(builder: (_) => const AccountManagementScreen());

      // ── Waiter ───────────────────────────────────────────────
      case AppRoutes.waiterDashboard:
        return MaterialPageRoute(builder: (_) => const WaiterDashboard());
      case AppRoutes.waiterTables:
        return MaterialPageRoute(builder: (_) => const TableListScreen());
      case AppRoutes.waiterCreateOrder:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CreateOrderScreen(
            tableId: args?['tableId'] as String? ?? '',
            tableNumber: args?['tableNumber'] as int? ?? 0,
          ),
        );
      case AppRoutes.waiterCartDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CartDetailScreen(
            tableId: args?['tableId'] as String? ?? '',
            tableNumber: args?['tableNumber'] as int? ?? 0,
            cartItems: args?['cartItems'] as Map<String, int>? ?? {},
          ),
        );
      case AppRoutes.waiterOrders:
        final orderId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
        );

      // ── Barista ──────────────────────────────────────────────
      case AppRoutes.baristaDashboard:
        return MaterialPageRoute(builder: (_) => const BaristaDashboard());
      case AppRoutes.baristaOrders:
        return MaterialPageRoute(builder: (_) => const OrderQueueScreen());

      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }

  /// Trả về route khởi đầu theo role sau khi đăng nhập
  static String initialRouteFor(UserRole role) => switch (role) {
        UserRole.manager  => AppRoutes.managerDashboard,
        UserRole.waiter   => AppRoutes.waiterDashboard,
        UserRole.barista  => AppRoutes.baristaDashboard,
      };
}
