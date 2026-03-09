import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F1),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F4E37),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.coffee, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PRM393 Coffee',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C1A0E),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chọn vai trò để đăng nhập',
                  style: TextStyle(fontSize: 14, color: Color(0xFF9E7B5A)),
                ),
                const SizedBox(height: 40),

                // Role buttons
                _RoleButton(
                  icon: '👔',
                  title: 'Quản lý',
                  subtitle: 'Quản lý menu, bàn, đơn hàng & báo cáo',
                  color: const Color(0xFF6F4E37),
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.managerDashboard,
                  ),
                ),
                const SizedBox(height: 12),
                _RoleButton(
                  icon: '🧑‍💼',
                  title: 'Nhân viên phục vụ',
                  subtitle: 'Chọn bàn và tạo đơn hàng cho khách',
                  color: const Color(0xFF2E7D32),
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.waiterDashboard,
                  ),
                ),
                const SizedBox(height: 12),
                _RoleButton(
                  icon: '☕',
                  title: 'Barista',
                  subtitle: 'Xem và xử lý hàng đợi pha chế',
                  color: const Color(0xFF1565C0),
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.baristaDashboard,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
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
      shadowColor: color.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E7B5A),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
