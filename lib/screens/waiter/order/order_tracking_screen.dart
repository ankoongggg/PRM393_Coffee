import 'package:flutter/material.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // TODO: replace with OrderProvider.getOrderById
  late Map<String, dynamic> _order;

  @override
  void initState() {
    super.initState();
    _order = {
      'id': widget.orderId,
      'table': 2,
      'status': 'preparing',
      'time': '09:02',
      'items': [
        {'name': 'Cà phê sữa đá', 'qty': 2},
        {'name': 'Bánh croissant', 'qty': 1},
      ],
    };
  }

  final _steps = ['pending', 'preparing', 'completed', 'served'];
  final _stepLabels = ['Chờ pha', 'Đang pha', 'Xong', 'Đã phục vụ'];
  final _stepIcons = [Icons.hourglass_empty, Icons.local_cafe, Icons.check_circle, Icons.room_service];

  int get _currentStep => _steps.indexOf(_order['status']);

  Color _statusColor(String s) => switch (s) {
    'pending' => const Color(0xFFE67E22),
    'preparing' => const Color(0xFF2980B9),
    'completed' => const Color(0xFF27AE60),
    'served' => const Color(0xFF8E44AD),
    _ => Colors.grey,
  };

  String _statusLabel(String s) => switch (s) {
    'pending' => 'Chờ pha',
    'preparing' => 'Đang pha',
    'completed' => 'Đã hoàn thành – Sẵn phục vụ!',
    'served' => 'Đã phục vụ ✓',
    _ => s,
  };

  @override
  Widget build(BuildContext context) {
    final status = _order['status'] as String;
    final isCompleted = status == 'completed';
    final isServed = status == 'served';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Theo dõi - ${_order['id']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusCard(status),
            const SizedBox(height: 16),
            _buildTimeline(),
            const SizedBox(height: 16),
            _buildItemsCard(),
            const SizedBox(height: 24),
            if (isCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E44AD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.room_service, color: Colors.white),
                  label: const Text('Đã phục vụ khách', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () {
                    setState(() => _order['status'] = 'served');
                    // TODO: OrderProvider.updateStatus(orderId, OrderStatus.served)
                  },
                ),
              ),
            if (isServed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E44AD).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8E44AD).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF8E44AD)),
                    SizedBox(width: 8),
                    Text('Đơn đã hoàn tất!', style: TextStyle(color: Color(0xFF8E44AD), fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _statusColor(status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(_stepIcons[_currentStep.clamp(0, _stepIcons.length - 1)], size: 40, color: Colors.white),
          const SizedBox(height: 10),
          Text(_statusLabel(status), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('Bàn ${_order['table']} • ${_order['time']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tiến trình', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A3C1F))),
          const SizedBox(height: 16),
          Column(
            children: List.generate(_steps.length, (i) {
              final done = i <= _currentStep;
              final isCurrent = i == _currentStep;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? const Color(0xFF2E7D32) : const Color(0xFFE8F5E9),
                          border: isCurrent ? Border.all(color: const Color(0xFF4CAF50), width: 2.5) : null,
                        ),
                        child: Icon(_stepIcons[i], size: 16, color: done ? Colors.white : const Color(0xFF9E9E9E)),
                      ),
                      if (i < _steps.length - 1)
                        Container(width: 2, height: 24, color: done ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _stepLabels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: done ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ],
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Món đã gọi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A3C1F))),
          const Divider(height: 20),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.local_cafe, size: 16, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 13))),
                Text('x${item['qty']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
