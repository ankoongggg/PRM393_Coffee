import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/order_provider.dart';
import '../../../models/order_model.dart';
import '../../../core/enums/order_status.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  String _formatPrice(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Color _statusColor(OrderStatus s) => switch (s) {
    OrderStatus.pending => const Color(0xFFE67E22),
    OrderStatus.preparing => const Color(0xFF2980B9),
    OrderStatus.completed => const Color(0xFF27AE60),
    OrderStatus.served => const Color(0xFF27AE60),
    OrderStatus.cancelled => Colors.grey,
  };

  String _statusLabel(OrderStatus s) => switch (s) {
    OrderStatus.pending => 'Chờ pha',
    OrderStatus.preparing => 'Đang pha',
    OrderStatus.completed => 'Hoàn thành',
    OrderStatus.served => 'Hoàn thành',
    OrderStatus.cancelled => 'Đã hủy',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        final order = provider.orders.where((o) => o.id == orderId).firstOrNull;

        if (order == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFFFBF9F5),
              elevation: 0,
              leading: const BackButton(color: Color(0xFF361F1A)),
              title: const Text('Không tìm thấy đơn hàng', style: TextStyle(color: Color(0xFF361F1A))),
            ),
            body: const Center(child: Text('Đơn hàng không tồn tại hoặc đã bị xóa')),
          );
        }

        final isCancelled = order.status == OrderStatus.cancelled;

        return Scaffold(
          backgroundColor: const Color(0xFFFBF9F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBF9F5),
            elevation: 0,
            shape: const Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF361F1A)),
              onPressed: () => Navigator.pop(context),
            ),
            // Rút gọn ID trên AppBar cho dễ nhìn
            title: Text('Đơn ${order.id.substring(0, 6).toUpperCase()}', style: const TextStyle(color: Color(0xFF361F1A), fontWeight: FontWeight.w800)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(order),
                const SizedBox(height: 16),
                _buildStatusTimeline(order),
                const SizedBox(height: 16),
                _buildItemsCard(order),
                const SizedBox(height: 16),
                _buildTotalCard(order),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(OrderModel order) {
    final timeStr = DateFormat('HH:mm').format(order.createdAt);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thông tin đơn', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF361F1A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel(order.status), style: TextStyle(color: _statusColor(order.status), fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF0EBE6)),
          _infoRow(Icons.table_bar, 'Bàn số', '${order.tableNumber}'),
          const SizedBox(height: 10),
          _infoRow(Icons.person_outline, 'Nhân viên', order.waiterName),
          const SizedBox(height: 10),
          _infoRow(Icons.access_time, 'Giờ tạo', timeStr),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF504442)),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontSize: 13, color: Color(0xFF504442), fontWeight: FontWeight.w500)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF361F1A))),
    ],
  );

  Widget _buildStatusTimeline(OrderModel order) {
    final steps = [
      {'key': OrderStatus.pending, 'label': 'Chờ pha', 'icon': Icons.hourglass_empty},
      {'key': OrderStatus.preparing, 'label': 'Đang pha', 'icon': Icons.local_cafe},
      {'key': OrderStatus.completed, 'label': 'Xong', 'icon': Icons.check_circle_outline},
    ];

    int currentIndex = steps.indexWhere((step) => step['key'] == order.status);
    if (order.status == OrderStatus.served) currentIndex = 2; // Gộp chung "Hoàn thành" 

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF361F1A))),
          const SizedBox(height: 20),
          Row(
            children: List.generate(steps.length, (i) {
              final isCancelled = order.status == OrderStatus.cancelled;
              final isDone = !isCancelled && currentIndex >= 0 && i <= currentIndex;
              final isCurrent = !isCancelled && currentIndex >= 0 && i == currentIndex;

              // Màu cho trạng thái hủy thì hiện mờ
              final circleColor = isDone ? const Color(0xFF361F1A) : const Color(0xFFE4E2DE);
              final iconColor = isDone ? Colors.white : const Color(0xFF504442);
              final textColor = isDone ? const Color(0xFF361F1A) : const Color(0xFF504442);
              
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
                              color: isCancelled && isCurrent ? Colors.red : circleColor,
                              border: isCurrent && !isCancelled ? Border.all(color: const Color(0xFF361F1A).withOpacity(0.5), width: 2.5) : null,
                            ),
                            child: Icon(steps[i]['icon'] as IconData, size: 18, color: isCancelled && isCurrent ? Colors.white : iconColor),
                          ),
                          const SizedBox(height: 6),
                          Text(steps[i]['label'] as String, style: TextStyle(fontSize: 10, color: textColor, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        flex: 0,
                        child: Container(
                          height: 2,
                          width: 24,
                          color: (i < currentIndex && !isCancelled) ? const Color(0xFF361F1A) : const Color(0xFFE4E2DE),
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

  Widget _buildItemsCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Danh sách món', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF361F1A))),
          const Divider(height: 24, color: Color(0xFFF0EBE6)),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBF7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE4E2DE)),
                  ),
                  child: const Icon(Icons.local_cafe, size: 14, color: Color(0xFF504442)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item.menuItemName, style: const TextStyle(fontSize: 14, color: Color(0xFF361F1A), fontWeight: FontWeight.w500))),
                Text('x${item.quantity}', style: const TextStyle(fontSize: 13, color: Color(0xFF504442), fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                Text('${_formatPrice(item.subtotal)}đ',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF361F1A))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTotalCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF361F1A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.4), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Tổng cộng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          Text('${_formatPrice(order.totalAmount)}đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
        ],
      ),
    );
  }
}
