import 'package:flutter/material.dart';

class OrderQueueScreen extends StatefulWidget {
  const OrderQueueScreen({super.key});

  @override
  State<OrderQueueScreen> createState() => _OrderQueueScreenState();
}

class _OrderQueueScreenState extends State<OrderQueueScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // TODO: replace with OrderProvider.pendingOrders / preparingOrders
  final List<Map<String, dynamic>> _pendingOrders = [
    {'id': 'ORD001', 'table': 2, 'waiter': 'Nguyễn An', 'time': '08:45', 'items': [
      {'name': 'Cà phê sữa đá', 'qty': 2},
      {'name': 'Bạc xỉu', 'qty': 1},
    ]},
    {'id': 'ORD005', 'table': 5, 'waiter': 'Trần Bình', 'time': '09:45', 'items': [
      {'name': 'Matcha latte', 'qty': 2},
      {'name': 'Trà đào', 'qty': 2},
    ]},
  ];

  final List<Map<String, dynamic>> _preparingOrders = [
    {'id': 'ORD002', 'table': 4, 'waiter': 'Trần Bình', 'time': '09:02', 'items': [
      {'name': 'Cà phê đen', 'qty': 1},
      {'name': 'Bánh croissant', 'qty': 1},
    ]},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startPreparing(Map<String, dynamic> order) {
    setState(() {
      _pendingOrders.removeWhere((o) => o['id'] == order['id']);
      _preparingOrders.add(order);
    });
    // TODO: OrderProvider.updateStatus(orderId, OrderStatus.preparing)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bắt đầu pha ${order['id']}'), backgroundColor: const Color(0xFF2196F3)),
    );
  }

  void _completeOrder(Map<String, dynamic> order) {
    setState(() {
      _preparingOrders.removeWhere((o) => o['id'] == order['id']);
    });
    // TODO: OrderProvider.updateStatus(orderId, OrderStatus.completed)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Hoàn thành ${order['id']} – Thông báo Waiter!'), backgroundColor: const Color(0xFF2E7D32)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Hàng đợi pha chế', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_empty, size: 16),
                  const SizedBox(width: 6),
                  Text('Chờ pha (${_pendingOrders.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_cafe, size: 16),
                  const SizedBox(width: 6),
                  Text('Đang pha (${_preparingOrders.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildPreparingTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingOrders.isEmpty) {
      return _buildEmptyState('Không có đơn đang chờ', Icons.hourglass_empty);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildOrderCard(
        _pendingOrders[i],
        actionLabel: 'Bắt đầu pha',
        actionColor: const Color(0xFF1565C0),
        actionIcon: Icons.local_cafe,
        onAction: () => _startPreparing(_pendingOrders[i]),
        statusColor: const Color(0xFFE67E22),
        statusLabel: 'Chờ pha',
      ),
    );
  }

  Widget _buildPreparingTab() {
    if (_preparingOrders.isEmpty) {
      return _buildEmptyState('Không có đơn đang pha', Icons.local_cafe);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _preparingOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildOrderCard(
        _preparingOrders[i],
        actionLabel: 'Hoàn thành',
        actionColor: const Color(0xFF2E7D32),
        actionIcon: Icons.check_circle_outline,
        onAction: () => _completeOrder(_preparingOrders[i]),
        statusColor: const Color(0xFF2196F3),
        statusLabel: 'Đang pha',
      ),
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> order, {
    required String actionLabel,
    required Color actionColor,
    required IconData actionIcon,
    required VoidCallback onAction,
    required Color statusColor,
    required String statusLabel,
  }) {
    final items = order['items'] as List;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.receipt, color: statusColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A237E))),
                      Row(
                        children: [
                          const Icon(Icons.table_bar, size: 12, color: Color(0xFF7986CB)),
                          const SizedBox(width: 3),
                          Text('Bàn ${order['table']}', style: const TextStyle(fontSize: 12, color: Color(0xFF7986CB))),
                          const SizedBox(width: 8),
                          const Icon(Icons.person_outline, size: 12, color: Color(0xFF7986CB)),
                          const SizedBox(width: 3),
                          Text(order['waiter'], style: const TextStyle(fontSize: 12, color: Color(0xFF7986CB))),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusLabel, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 11, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 2),
                        Text(order['time'], style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            // Items
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF7986CB)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 13))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('x${item['qty']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 10),
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(actionIcon, color: Colors.white, size: 18),
                label: Text(actionLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: onAction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: const Color(0xFF7986CB).withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 15, color: Color(0xFF7986CB))),
        ],
      ),
    );
  }
}
