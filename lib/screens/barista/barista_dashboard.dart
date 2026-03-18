import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class BaristaDashboard extends StatelessWidget {
  const BaristaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
        automaticallyImplyLeading: false,
        title: const Text('☕ Barista', style: TextStyle(color: Color(0xFF361F1A), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF361F1A)),
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
              'Xin chào, Barista!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF361F1A)),
            ),
            const SizedBox(height: 4),
            const Text('Hàng đợi pha chế hôm nay', style: TextStyle(color: Color(0xFF504442), fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 0,
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.baristaOrders),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.transparent),
                    boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003A76).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.queue, color: Color(0xFF003A76), size: 32),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hàng đợi Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF361F1A))),
                            SizedBox(height: 4),
                            Text('Xem và xử lý đơn đang chờ pha chế', style: TextStyle(fontSize: 13, color: Color(0xFF504442))),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 24, color: Color(0xFF003A76)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
