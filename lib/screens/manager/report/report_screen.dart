import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/report_provider.dart';
import '../../../routes/app_routes.dart';
import '../manager_navigation_bar.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedNavIndex = 4; // STATS tab (updated to 4 after adding STOCK)

  @override
  void initState() {
    super.initState();
    // ✅ Fetch báo cáo khi mở screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      reportProvider.fetchTodayReport();
      reportProvider.fetchLast7DaysRevenue();
      reportProvider.fetchTopSellingItems();
    });
  }

  String _formatPrice(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        if (reportProvider.isLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFFFBF9F5),
            appBar: AppBar(
              backgroundColor: const Color(0xFFFBF9F5),
              elevation: 0,
              automaticallyImplyLeading: false,
              shape: const Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
              title: const Text('Báo cáo doanh thu', style: TextStyle(color: Color(0xFF361F1A), fontWeight: FontWeight.w800)),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final report = reportProvider.todayReport;
        final revenueByDay = reportProvider.revenueByDay;
        final topItems = reportProvider.topSellingItems;

        return Scaffold(
          backgroundColor: const Color(0xFFFBF9F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBF9F5),
            elevation: 0,
            automaticallyImplyLeading: false,
            shape: const Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
            title: const Text('Báo cáo doanh thu', style: TextStyle(color: Color(0xFF361F1A), fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF361F1A)),
                onPressed: () {
                  reportProvider.fetchTodayReport();
                  reportProvider.fetchLast7DaysRevenue();
                  reportProvider.fetchTopSellingItems();
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFF361F1A)),
                tooltip: 'Đăng xuất',
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateLabel(report),
                const SizedBox(height: 16),
                _buildSummaryCards(report),
                const SizedBox(height: 20),
                _buildSectionTitle('Doanh thu 7 ngày'),
                const SizedBox(height: 12),
                _buildBarChart(revenueByDay),
                const SizedBox(height: 20),
                _buildSectionTitle('Top món bán chạy'),
                const SizedBox(height: 12),
                _buildTopItemsList(topItems),
              ],
            ),
          ),
          bottomNavigationBar: buildManagerBottomNavigation(
            context: context,
            selectedIndex: _selectedNavIndex,
            onIndexChanged: (index) => setState(() => _selectedNavIndex = index),
          ),
        );
      },
    );
  }

  Widget _buildDateLabel(ReportData report) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assessment, size: 16, color: Color(0xFF361F1A)),
          SizedBox(width: 8),
          Text('Tổng quan tất cả đơn hàng', style: TextStyle(fontSize: 13, color: Color(0xFF361F1A), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days[weekday - 1];
  }

  Widget _buildSummaryCards(ReportData report) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.attach_money,
            label: 'Doanh thu',
            value: '${_formatPrice(report.totalRevenue)}đ',
            color: const Color(0xFF27AE60),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.receipt_long,
            label: 'Đơn hàng',
            value: '${report.totalOrders}',
            color: const Color(0xFF2980B9),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.trending_up,
            label: 'Trung bình',
            value: '${_formatPrice(report.averageOrderValue)}đ',
            color: const Color(0xFFE67E22),
          ),
        ),
      ],
    );
  }
  Widget _buildSectionTitle(String title) => Text(title,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF361F1A)));

  Widget _buildBarChart(Map<String, double> revenueByDay) {
    if (revenueByDay.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
        ),
        child: const Center(child: Text('Không có dữ liệu', style: TextStyle(color: Color(0xFF504442)))),
      );
    }

    final amounts = revenueByDay.values.toList();
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: revenueByDay.entries.map((e) {
                final amount = e.value;
                final ratio = maxAmount > 0 ? amount / maxAmount : 0;
                final isMax = amount == maxAmount;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${(amount / 1000).round()}k', style: TextStyle(fontSize: 10, color: isMax ? const Color(0xFF361F1A) : const Color(0xFF504442), fontWeight: isMax ? FontWeight.w800 : FontWeight.w500)),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 28,
                      height: (100 * ratio).toDouble(),
                      decoration: BoxDecoration(
                        color: isMax ? const Color(0xFF361F1A) : const Color(0xFFE4E2DE),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: revenueByDay.keys.map((day) => Text(day, style: const TextStyle(fontSize: 12, color: Color(0xFF504442), fontWeight: FontWeight.w600))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemsList(Map<String, int> topItems) {
    if (topItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
        ),
        child: const Center(child: Text('Không có dữ liệu', style: TextStyle(color: Color(0xFF504442)))),
      );
    }

    final items = topItems.entries.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: i == 0 ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                        : i == 1 ? const Color(0xFFC0C0C0).withValues(alpha: 0.2)
                        : i == 2 ? const Color(0xFFCD7F32).withValues(alpha: 0.2)
                        : const Color(0xFFF5E6D3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${i + 1}', style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: i == 0 ? const Color(0xFFB8860B) : i == 1 ? Colors.grey : i == 2 ? const Color(0xFF8B4513) : const Color(0xFF9E7B5A),
                    )),
                  ),
                ),
                title: Text(item.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF361F1A))),
                subtitle: Text('${item.value} ly bán ra', style: const TextStyle(fontSize: 12, color: Color(0xFF504442))),
                trailing: Text('${_formatPrice(item.value * 35000.0)}đ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1B6D24))),
              ),
              if (i < items.length - 1) const Divider(height: 1, indent: 64, color: Color(0xFFF0EBE6)),
            ],
          );
        }),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF361F1A))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF504442), fontWeight: FontWeight.w500)),
      ],
    ),
  );
}
