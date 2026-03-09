import 'package:flutter/material.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  // TODO: replace with OrderProvider.orders
  final List<Map<String, dynamic>> _orders = [
    {'id': 'ORD001', 'table': 2, 'waiter': 'Nguyễn An', 'items': 3, 'total': 125000, 'status': 'pending', 'time': '08:45'},
    {'id': 'ORD002', 'table': 4, 'waiter': 'Trần Bình', 'items': 2, 'total': 89000, 'status': 'preparing', 'time': '09:02'},
    {'id': 'ORD003', 'table': 1, 'waiter': 'Lê Chi', 'items': 5, 'total': 210000, 'status': 'completed', 'time': '09:15'},
    {'id': 'ORD004', 'table': 3, 'waiter': 'Nguyễn An', 'items': 1, 'total': 45000, 'status': 'served', 'time': '09:30'},
    {'id': 'ORD005', 'table': 5, 'waiter': 'Trần Bình', 'items': 4, 'total': 168000, 'status': 'pending', 'time': '09:45'},
    {'id': 'ORD006', 'table': 6, 'waiter': 'Lê Chi', 'items': 2, 'total': 76000, 'status': 'cancelled', 'time': '10:00'},
  ];

  String _selectedFilter = 'all';
  final _filters = ['all', 'pending', 'preparing', 'completed', 'served', 'cancelled'];
  final _filterLabels = {
    'all': 'Tất cả', 'pending': 'Chờ pha', 'preparing': 'Đang pha',
    'completed': 'Xong', 'served': 'Đã phục vụ', 'cancelled': 'Đã hủy',
  };

  Color _statusColor(String s) => switch (s) {
    'pending' => const Color(0xFFE67E22),
    'preparing' => const Color(0xFF2980B9),
    'completed' => const Color(0xFF27AE60),
    'served' => const Color(0xFF8E44AD),
    'cancelled' => Colors.grey,
    _ => Colors.grey,
  };

  String _statusLabel(String s) => switch (s) {
    'pending' => 'Chờ pha',
    'preparing' => 'Đang pha',
    'completed' => 'Hoàn thành',
    'served' => 'Đã phục vụ',
    'cancelled' => 'Đã hủy',
    _ => s,
  };

  List<Map<String, dynamic>> get _filtered =>
      _selectedFilter == 'all' ? _orders : _orders.where((o) => o['status'] == _selectedFilter).toList();

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
        title: const Text('Quản lý Đơn hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildSummaryRow(),
          Expanded(child: _buildOrderList()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final selected = f == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF6F4E37) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6F4E37)),
              ),
              child: Text(
                _filterLabels[f]!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF6F4E37),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow() {
    final total = _filtered.fold<int>(0, (s, o) => s + (o['total'] as int));
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, size: 16, color: Color(0xFF9E7B5A)),
          const SizedBox(width: 6),
          Text('${_filtered.length} đơn', style: const TextStyle(fontSize: 13, color: Color(0xFF6F4E37), fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('Tổng: ${_formatPrice(total)}đ', style: const TextStyle(fontSize: 13, color: Color(0xFF6F4E37), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    if (_filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFD4A864)),
            SizedBox(height: 8),
            Text('Không có đơn hàng', style: TextStyle(color: Color(0xFF9E7B5A))),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildOrderCard(_filtered[i]),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final statusColor = _statusColor(order['status']);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, '/manager/orders/detail', arguments: order['id']),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(order['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C1A0E))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_statusLabel(order['status']), style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.table_bar, size: 12, color: Color(0xFF9E7B5A)),
                        const SizedBox(width: 3),
                        Text('Bàn ${order['table']}', style: const TextStyle(fontSize: 12, color: Color(0xFF9E7B5A))),
                        const SizedBox(width: 10),
                        const Icon(Icons.person_outline, size: 12, color: Color(0xFF9E7B5A)),
                        const SizedBox(width: 3),
                        Text(order['waiter'], style: const TextStyle(fontSize: 12, color: Color(0xFF9E7B5A))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.local_cafe_outlined, size: 12, color: Color(0xFF9E7B5A)),
                        const SizedBox(width: 3),
                        Text('${order['items']} món', style: const TextStyle(fontSize: 12, color: Color(0xFF9E7B5A))),
                        const SizedBox(width: 10),
                        const Icon(Icons.access_time, size: 12, color: Color(0xFF9E7B5A)),
                        const SizedBox(width: 3),
                        Text(order['time'], style: const TextStyle(fontSize: 12, color: Color(0xFF9E7B5A))),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${_formatPrice(order['total'] as int)}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6F4E37))),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right, color: Color(0xFFD4A864)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
