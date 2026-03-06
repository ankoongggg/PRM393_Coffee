import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  // TODO: replace with ReportProvider data
  static const _revenueByDay = [
    {'day': 'T2', 'amount': 850000},
    {'day': 'T3', 'amount': 1200000},
    {'day': 'T4', 'amount': 970000},
    {'day': 'T5', 'amount': 1450000},
    {'day': 'T6', 'amount': 1320000},
    {'day': 'T7', 'amount': 1780000},
    {'day': 'CN', 'amount': 2100000},
  ];

  static const _topItems = [
    {'name': 'Cà phê sữa đá', 'qty': 48, 'revenue': 1680000},
    {'name': 'Matcha latte', 'qty': 32, 'revenue': 1440000},
    {'name': 'Bạc xỉu', 'qty': 27, 'revenue': 810000},
    {'name': 'Cà phê đen', 'qty': 25, 'revenue': 625000},
    {'name': 'Bánh croissant', 'qty': 20, 'revenue': 500000},
  ];

  static const int _todayRevenue = 2100000;
  static const int _todayOrders = 38;
  static const int _todayCustomers = 52;

  String _formatPrice(int amount) =>
      amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F4E37),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Báo cáo doanh thu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateLabel(),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 20),
            _buildSectionTitle('Doanh thu 7 ngày'),
            const SizedBox(height: 12),
            _buildBarChart(),
            const SizedBox(height: 20),
            _buildSectionTitle('Top món bán chạy'),
            const SizedBox(height: 12),
            _buildTopItemsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A864).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.today, size: 14, color: Color(0xFF6F4E37)),
          SizedBox(width: 6),
          Text('Hôm nay - Chủ nhật', style: TextStyle(fontSize: 12, color: Color(0xFF6F4E37), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _SummaryCard(icon: Icons.attach_money, label: 'Doanh thu', value: '${_formatPrice(_todayRevenue)}đ', color: const Color(0xFF27AE60))),
        const SizedBox(width: 10),
        Expanded(child: _SummaryCard(icon: Icons.receipt_long, label: 'Đơn hàng', value: '$_todayOrders', color: const Color(0xFF2980B9))),
        const SizedBox(width: 10),
        Expanded(child: _SummaryCard(icon: Icons.people, label: 'Khách', value: '$_todayCustomers', color: const Color(0xFFE67E22))),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Text(title,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E)));

  Widget _buildBarChart() {
    final maxAmount = _revenueByDay.map((d) => d['amount'] as int).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _revenueByDay.map((d) {
                final amount = d['amount'] as int;
                final ratio = amount / maxAmount;
                final isMax = amount == maxAmount;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${(amount / 1000).round()}k', style: TextStyle(fontSize: 9, color: isMax ? const Color(0xFF6F4E37) : const Color(0xFF9E7B5A), fontWeight: isMax ? FontWeight.bold : FontWeight.normal)),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 28,
                      height: 100 * ratio,
                      decoration: BoxDecoration(
                        color: isMax ? const Color(0xFF6F4E37) : const Color(0xFFD4A864).withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
            children: _revenueByDay.map((d) => Text(d['day'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF9E7B5A)))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        children: List.generate(_topItems.length, (i) {
          final item = _topItems[i];
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
                title: Text(item['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('${item['qty']} ly bán ra', style: const TextStyle(fontSize: 11, color: Color(0xFF9E7B5A))),
                trailing: Text('${_formatPrice(item['revenue'] as int)}đ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6F4E37))),
              ),
              if (i < _topItems.length - 1) const Divider(height: 1, indent: 56),
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
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E7B5A))),
      ],
    ),
  );
}
