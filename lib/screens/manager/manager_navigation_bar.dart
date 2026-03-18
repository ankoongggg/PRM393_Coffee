import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

/// Tạo bottom navigation bar cho manager screens
Widget buildManagerBottomNavigation({
  required BuildContext context,
  required int selectedIndex,
  required Function(int) onIndexChanged,
}) {
  const bgColor = Color(0xFFFBF9F5);
  const primary = Color(0xFF361F1A);
  const onSurface = Color(0xFF1B1C1A);
  const onSurfaceVariant = Color(0xFF504442);

  return Container(
    decoration: BoxDecoration(
      color: bgColor,
      border: Border(
        top: BorderSide(
          color: onSurface.withOpacity(0.1),
          width: 0.5,
        ),
      ),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(
              icon: Icons.restaurant_menu_rounded,
              label: 'MENU',
              isActive: selectedIndex == 0,
              onTap: () {
                onIndexChanged(0);
                Navigator.pushNamed(context, AppRoutes.managerMenu);
              },
            ),
            _NavItem(
              icon: Icons.table_bar_rounded,
              label: 'TABLES',
              isActive: selectedIndex == 1,
              onTap: () {
                onIndexChanged(1);
                Navigator.pushNamed(context, AppRoutes.managerTables);
              },
            ),
            _NavItem(
              icon: Icons.receipt_long_rounded,
              label: 'ORDERS',
              isActive: selectedIndex == 2,
              onTap: () {
                onIndexChanged(2);
                Navigator.pushNamed(context, AppRoutes.managerOrders);
              },
            ),
            _NavItem(
              icon: Icons.bar_chart_rounded,
              label: 'STATS',
              isActive: selectedIndex == 3,
              onTap: () {
                onIndexChanged(3);
                Navigator.pushNamed(context, AppRoutes.managerRevenue);
              },
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'ACCOUNT',
              isActive: selectedIndex == 4,
              onTap: () {
                onIndexChanged(4);
                Navigator.pushNamed(context, AppRoutes.managerAccounts);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive
                ? const Color(0xFF361F1A)
                : const Color(0xFF504442).withOpacity(0.6),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isActive
                  ? const Color(0xFF361F1A)
                  : const Color(0xFF504442).withOpacity(0.6),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
