import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/enums/order_status.dart';

class TableOrdersScreen extends StatefulWidget {
  final String tableId;
  final int tableNumber;
  final int capacity;

  const TableOrdersScreen({
    super.key,
    required this.tableId,
    required this.tableNumber,
    required this.capacity,
  });

  @override
  State<TableOrdersScreen> createState() => _TableOrdersScreenState();
}

class _TableOrdersScreenState extends State<TableOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).startOrderListener();
    });
  }

  String _formatPrice(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Color _statusColor(String statusString) => switch (statusString) {
    'pending' => const Color(0xFFE67E22),
    'preparing' => const Color(0xFF2980B9),
    'completed' => const Color(0xFF27AE60),
    'cancelled' => Colors.grey,
    _ => Colors.grey,
  };

  String _statusLabel(String statusString) => switch (statusString) {
    'pending' => 'Chờ pha',
    'preparing' => 'Đang pha',
    'completed' => 'Hoàn thành',
    'cancelled' => 'Đã hủy',
    _ => statusString,
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        // Lấy tất cả đơn hàng của bàn này
        final tableOrders = orderProvider.ordersByTable(widget.tableId);

        return Scaffold(
          backgroundColor: const Color(0xFFFAF6F1),
          appBar: AppBar(
            backgroundColor: const Color(0xFF6F4E37),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Bàn ${widget.tableNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => orderProvider.startOrderListener(),
              ),
            ],
          ),
          body: tableOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: const Color(0xFFD4A864).withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bàn này chưa có đơn hàng',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF9E7B5A).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSummaryCard(tableOrders),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        itemCount: tableOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildOrderCard(tableOrders[i]),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSummaryCard(List orders) {
    final totalAmount =
        orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final totalItems =
        orders.fold<int>(0, (sum, o) => sum + (o.items.length as int));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text(
                'Tổng đơn',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E7B5A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${orders.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F4E37),
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE8D5C0),
          ),
          Column(
            children: [
              const Text(
                'Tổng món',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E7B5A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalItems',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F4E37),
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE8D5C0),
          ),
          Column(
            children: [
              const Text(
                'Tổng tiền',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E7B5A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatPrice(totalAmount)}đ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final statusString = order.status.toString().split('.').last;
    final statusColor = _statusColor(statusString);
    
    // Format ngày giờ từ DateTime
    final dateTime = order.createdAt as DateTime;
    final dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.id.substring(0, 8).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C1A0E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ngày: $dateStr',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9E7B5A),
                        ),
                      ),
                      Text(
                        'Giờ: $timeStr',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9E7B5A),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(statusString),
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Hiển thị các item
            ...order.items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: idx < order.items.length - 1 ? 8 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.menuItemName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2C1A0E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatPrice(item.unitPrice)}đ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C1A0E),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: const Color(0xFFE8D5C0),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F4E37),
                  ),
                ),
                Text(
                  '${_formatPrice(order.totalAmount)}đ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
