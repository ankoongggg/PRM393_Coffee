import 'package:flutter/material.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  // TODO: replace with OrderProvider.getOrderById(orderId)
  late Map<String, dynamic> _order;

  final _statusFlow = ['pending', 'preparing', 'completed'];

  @override
  void initState() {
    super.initState();
    // Mock data
    _order = {
      'id': widget.orderId,
      'table': 4,
      'waiter': 'Trần Bình',
      'time': '09:02',
      'status': 'preparing',
      'items': [
        {'name': 'Cà phê sữa đá', 'qty': 2, 'price': 35000},
        {'name': 'Bánh croissant', 'qty': 1, 'price': 25000},
        {'name': 'Matcha latte', 'qty': 1, 'price': 45000},
      ],
    };
  }

  int get _total => (_order['items'] as List)
      .fold(0, (s, i) => s + (i['qty'] as int) * (i['price'] as int));

  String _formatPrice(int amount) =>
      amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Color _statusColor(String s) => switch (s) {
    'pending' => const Color(0xFFE67E22),
    'preparing' => const Color(0xFF2980B9),
    'completed' => const Color(0xFF27AE60),
    'cancelled' => Colors.grey,
    _ => Colors.grey,
  };

  String _statusLabel(String s) => switch (s) {
    'pending' => 'Chờ pha',
    'preparing' => 'Đang pha',
    'completed' => 'Hoàn thành',
    'cancelled' => 'Đã hủy',
    _ => s,
  };

  void _advanceStatus() {
    final currentIndex = _statusFlow.indexOf(_order['status']);
    if (currentIndex < _statusFlow.length - 1) {
      setState(() => _order['status'] = _statusFlow[currentIndex + 1]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trạng thái: ${_statusLabel(_order['status'])}'),
          backgroundColor: _statusColor(_order['status']),
        ),
      );
    }
  }

  void _cancelOrder() {
    final status = _order['status'] as String;
    if (status == 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Đơn đã hoàn thành nên không thể hủy'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Bạn có chắc muốn hủy đơn này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _order['status'] = 'cancelled');
              Navigator.pop(context);
            },
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _order['status'] as String;
    final canAdvance = _statusFlow.contains(status) && status != 'served';
    final isCancelled = status == 'cancelled';
    final isCompleted = status == 'completed';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F4E37),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Đơn ${_order['id']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (!isCancelled && !isCompleted && status != 'served')
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.white70),
              tooltip: 'Hủy đơn',
              onPressed: _cancelOrder,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildStatusTimeline(),
            const SizedBox(height: 16),
            _buildItemsCard(),
            const SizedBox(height: 16),
            _buildTotalCard(),
            const SizedBox(height: 24),
            if (canAdvance && !isCancelled)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F4E37),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: Text(
                    'Chuyển sang: ${_statusLabel(_statusFlow[_statusFlow.indexOf(status) + 1])}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: _advanceStatus,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thông tin đơn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C1A0E))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(_order['status']).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel(_order['status']), style: TextStyle(color: _statusColor(_order['status']), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 20),
          _infoRow(Icons.table_bar, 'Bàn số', '${_order['table']}'),
          const SizedBox(height: 8),
          _infoRow(Icons.person_outline, 'Nhân viên', _order['waiter']),
          const SizedBox(height: 8),
          _infoRow(Icons.access_time, 'Giờ tạo', _order['time']),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF9E7B5A)),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontSize: 13, color: Color(0xFF9E7B5A))),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C1A0E))),
    ],
  );

  Widget _buildStatusTimeline() {
    final steps = [
      {'key': 'pending', 'label': 'Chờ pha', 'icon': Icons.hourglass_empty},
      {'key': 'preparing', 'label': 'Đang pha', 'icon': Icons.local_cafe},
      {'key': 'completed', 'label': 'Xong', 'icon': Icons.check_circle_outline},
    ];
    final currentIndex = _statusFlow.indexOf(_order['status']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C1A0E))),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (i) {
              final done = i <= currentIndex && !(_order['status'] == 'cancelled');
              final isCurrent = i == currentIndex && !(_order['status'] == 'cancelled');
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done ? const Color(0xFF6F4E37) : const Color(0xFFE8D5C0),
                              border: isCurrent ? Border.all(color: const Color(0xFFD4A864), width: 2.5) : null,
                            ),
                            child: Icon(steps[i]['icon'] as IconData, size: 18, color: done ? Colors.white : const Color(0xFF9E7B5A)),
                          ),
                          const SizedBox(height: 4),
                          Text(steps[i]['label'] as String, style: TextStyle(fontSize: 9, color: done ? const Color(0xFF6F4E37) : const Color(0xFF9E7B5A), fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        flex: 0,
                        child: Container(
                          height: 2,
                          width: 20,
                          color: i < currentIndex ? const Color(0xFF6F4E37) : const Color(0xFFE8D5C0),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    final items = _order['items'] as List;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Danh sách món', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C1A0E))),
          const Divider(height: 20),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6D3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.local_cafe, size: 14, color: Color(0xFF9E7B5A)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 13, color: Color(0xFF2C1A0E)))),
                Text('x${item['qty']}', style: const TextStyle(fontSize: 13, color: Color(0xFF9E7B5A))),
                const SizedBox(width: 12),
                Text('${_formatPrice((item['qty'] as int) * (item['price'] as int))}đ',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6F4E37))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6F4E37),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Tổng cộng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text('${_formatPrice(_total)}đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
    );
  }
}
