import 'package:flutter/material.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // Theme colors consistent with HTML template
  static const _bgWarm = Color(0xFFFDF8F6);
  static const _coffee50 = Color(0xFFFDF8F6);
  static const _coffee100 = Color(0xFFF2E8E5);
  static const _coffee200 = Color(0xFFEADDD7);
  static const _coffee600 = Color(0xFF8C634F);
  static const _coffee900 = Color(0xFF4A332D);

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
  final _stepIcons = [Icons.hourglass_empty_rounded, Icons.local_cafe_rounded, Icons.check_circle_rounded, Icons.room_service_rounded];

  int get _currentStep => _steps.indexOf(_order['status']);

  Color _statusColor(String s) => switch (s) {
    'pending' => const Color(0xFFD97706), // Orange
    'preparing' => const Color(0xFF2563EB), // Blue
    'completed' => const Color(0xFF059669), // Emerald
    'served' => _coffee600,
    _ => Colors.grey,
  };

  Color _statusBgColor(String s) => switch (s) {
    'pending' => const Color(0xFFFEF3C7),
    'preparing' => const Color(0xFFDBEAFE),
    'completed' => const Color(0xFFD1FAE5),
    'served' => const Color(0xFFFDF8F6),
    _ => Colors.grey[100]!,
  };

  String _statusLabel(String s) => switch (s) {
    'pending' => 'Chờ pha',
    'preparing' => 'Đang pha',
    'completed' => 'Đã hoàn thành - Sẵn sàng!',
    'served' => 'Đã phục vụ ✓',
    _ => s,
  };

  @override
  Widget build(BuildContext context) {
    final status = _order['status'] as String;
    final isCompleted = status == 'completed';
    final isServed = status == 'served';

    return Scaffold(
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatusCard(status),
                    const SizedBox(height: 20),
                    _buildTimeline(),
                    const SizedBox(height: 20),
                    _buildItemsCard(),
                    const SizedBox(height: 32),
                    if (isCompleted)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _coffee600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.room_service_rounded),
                          label: const Text('XÁC NHẬN ĐÃ PHỤC VỤ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                          onPressed: () {
                            setState(() => _order['status'] = 'served');
                            // TODO: OrderProvider.updateStatus(orderId, OrderStatus.served)
                          },
                        ),
                      ),
                    if (isServed)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF059669)),
                            SizedBox(width: 12),
                            Text('Đơn đã phục vụ xong!', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _coffee100)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: _coffee900),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('THEO DÕI ĐƠN HÀNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _coffee600, letterSpacing: 0.5)),
              Text('Mã #${_order['id']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _coffee900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _statusBgColor(status),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), shape: BoxShape.circle),
            child: Icon(_stepIcons[_currentStep.clamp(0, _stepIcons.length - 1)], size: 48, color: _statusColor(status)),
          ),
          const SizedBox(height: 16),
          Text(_statusLabel(status), style: TextStyle(color: _statusColor(status), fontSize: 18, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
            child: Text('Bàn ${_order['table']} • Lúc ${_order['time']}', style: TextStyle(color: _statusColor(status).withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _coffee100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tiến trình', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _coffee900)),
          const SizedBox(height: 20),
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
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? _coffee600 : const Color(0xFFF5EDE0),
                          border: isCurrent ? Border.all(color: _coffee200, width: 4) : null,
                        ),
                        child: Icon(_stepIcons[i], size: 16, color: done ? Colors.white : _coffee200),
                      ),
                      if (i < _steps.length - 1)
                        Container(width: 2, height: 32, color: done ? _coffee600 : _coffee100),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _stepLabels[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        color: done ? _coffee900 : Colors.grey,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _coffee100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Món đã gọi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _coffee900)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: _coffee100),
          ),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _coffee50, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.local_cafe_rounded, size: 20, color: _coffee600),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _coffee900))),
                Text('x${item['qty']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _coffee600)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
