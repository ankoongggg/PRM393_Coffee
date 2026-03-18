import 'package:flutter/material.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // Theme colors consistent with HTML template
  static const _bgWarm = Color(0xFFFBF9F5);
  static const _coffee100 = Color(0xFFF0EBE6);
  static const _coffee200 = Color(0xFFE4E2DE);
  static const _coffee600 = Color(0xFF504442);
  static const _coffee900 = Color(0xFF361F1A);

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
    'pending' => const Color(0xFF361F1A), // Dark
    'preparing' => const Color(0xFF361F1A), // Dark
    'completed' => const Color(0xFF1B6D24), // Green
    'served' => const Color(0xFF504442),
    _ => const Color(0xFFE4E2DE),
  };

  Color _statusBgColor(String s) => switch (s) {
    'pending' => const Color(0xFF361F1A).withOpacity(0.05),
    'preparing' => const Color(0xFF361F1A).withOpacity(0.05),
    'completed' => const Color(0xFF1B6D24).withOpacity(0.08),
    'served' => const Color(0xFFFBF9F5),
    _ => const Color(0xFFFBF9F5),
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
                            backgroundColor: const Color(0xFF361F1A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 4,
                            shadowColor: const Color(0xFF361F1A).withOpacity(0.3),
                          ),
                          icon: const Icon(Icons.room_service_rounded),
                          label: const Text('XÁC NHẬN ĐÃ PHỤC VỤ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.5)),
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
                          color: const Color(0xFF1B6D24).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF1B6D24).withOpacity(0.2)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF1B6D24)),
                            SizedBox(width: 12),
                            Text('Đơn đã phục vụ xong!', style: TextStyle(color: Color(0xFF1B6D24), fontWeight: FontWeight.w800, fontSize: 16)),
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
        border: Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
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
              const Text('THEO DÕI ĐƠN HÀNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF504442), letterSpacing: 0.5)),
              Text('Mã #${_order['id']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF361F1A))),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
            child: Text('Bàn ${_order['table']} • Lúc ${_order['time']}', style: TextStyle(color: _statusColor(status), fontSize: 14, fontWeight: FontWeight.w800)),
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
        border: Border.all(color: const Color(0xFFF0EBE6)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tiến trình', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF361F1A))),
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
                          color: done ? const Color(0xFF361F1A) : const Color(0xFFFBF9F5),
                          border: Border.all(color: done ? const Color(0xFF361F1A) : const Color(0xFFF0EBE6), width: isCurrent ? 4 : 1),
                        ),
                        child: Icon(_stepIcons[i], size: 16, color: done ? Colors.white : const Color(0xFFE4E2DE)),
                      ),
                      if (i < _steps.length - 1)
                        Container(width: 2, height: 32, color: done ? const Color(0xFF361F1A) : const Color(0xFFF0EBE6)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _stepLabels[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: done ? const Color(0xFF361F1A) : const Color(0xFFE4E2DE),
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
        border: Border.all(color: const Color(0xFFF0EBE6)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Món đã gọi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF361F1A))),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF0EBE6)),
          ),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFBF9F5), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF0EBE6))),
                  child: const Icon(Icons.local_cafe_rounded, size: 20, color: Color(0xFF361F1A)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF361F1A)))),
                Text('x${item['qty']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF361F1A))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
