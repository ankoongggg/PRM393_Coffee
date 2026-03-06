import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F4E37),
        title: const Text('👔 Quản lý', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(
              context, AppRoutes.login,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xin chào, Manager!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E)),
            ),
            const SizedBox(height: 4),
            const Text('Quản lý mọi thứ tại đây', style: TextStyle(color: Color(0xFF9E7B5A))),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _ModuleCard(
                    icon: Icons.restaurant_menu,
                    title: 'Quản lý Menu',
                    subtitle: 'Thêm, sửa, xóa món',
                    color: const Color(0xFF6F4E37),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.managerMenu),
                  ),
                  _ModuleCard(
                    icon: Icons.table_bar,
                    title: 'Quản lý Bàn',
                    subtitle: 'Trạng thái & cấu hình bàn',
                    color: const Color(0xFF2E7D32),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.managerTables),
                  ),
                  _ModuleCard(
                    icon: Icons.receipt_long,
                    title: 'Đơn hàng',
                    subtitle: 'Xem & cập nhật đơn',
                    color: const Color(0xFF1565C0),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.managerOrders),
                  ),
                  _ModuleCard(
                    icon: Icons.bar_chart,
                    title: 'Báo cáo',
                    subtitle: 'Doanh thu & thống kê',
                    color: const Color(0xFFE65100),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.managerRevenue),
                  ),
                  _ModuleCard(
                    icon: Icons.manage_accounts,
                    title: 'Tài khoản',
                    subtitle: 'Quản lý nhân viên',
                    color: const Color(0xFF6A1B9A),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.managerAccounts),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF9E7B5A))),
            ],
          ),
        ),
      ),
    );
  }
}
