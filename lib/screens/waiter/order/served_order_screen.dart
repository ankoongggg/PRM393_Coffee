import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/table_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/enums/order_status.dart';

class ServedOrderScreen extends StatefulWidget {
  final String tableId;
  final int tableNumber;

  const ServedOrderScreen({
    super.key,
    required this.tableId,
    required this.tableNumber,
  });

  @override
  State<ServedOrderScreen> createState() => _ServedOrderScreenState();
}

class _ServedOrderScreenState extends State<ServedOrderScreen> {
  bool _isProcessing = false;

  String _formatPrice(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  void _onComplete() async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: Text('Bàn ${widget.tableNumber} đã thanh toán?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Có',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() => _isProcessing = true);

      try {
        final tableProvider =
            Provider.of<TableProvider>(context, listen: false);
        await tableProvider.setTableAvailable(widget.tableId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã cập nhật bàn thành Trống'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
          Navigator.pop(context); // Quay lại TableListScreen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final tableOrders = orderProvider.ordersByTable(widget.tableId);
        
        // Lọc chỉ order đã hoàn thành (completed)
        final completedOrders = tableOrders
            .where((o) => o.status == OrderStatus.completed)
            .toList();
        
        // Kiểm tra có order chưa hoàn thành không
        final hasUncompletedOrders = tableOrders
            .where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.preparing)
            .isNotEmpty;
        
        // Nếu không có order hoàn thành
        if (completedOrders.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFF0F9F0),
            appBar: AppBar(
              backgroundColor: const Color(0xFF2E7D32),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Bàn ${widget.tableNumber} - Đang phục vụ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chờ Barista hoàn thành...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Hiển thị trạng thái các order đang chờ
                  if (hasUncompletedOrders)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Các đơn đang xử lý:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...tableOrders
                                .where((o) => o.status != OrderStatus.completed)
                                .map((o) => Text(
                                      '• ${o.status.displayName}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                      ),
                                    ))
                                .toList(),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        // Tính tổng tiền từ tất cả các order hoàn thành
        double totalAmount = 0;
        int totalItems = 0;
        for (var order in completedOrders) {
          totalAmount += order.totalAmount;
          totalItems += order.items.length;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF0F9F0),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2E7D32),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Bàn ${widget.tableNumber} - Chờ phục vụ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: completedOrders.length,
                  itemBuilder: (_, orderIndex) {
                    final order = completedOrders[orderIndex];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Đơn #${orderIndex + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '✓ Hoàn thành',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(''),
                                Text(
                                  _formatPrice(order.totalAmount) + 'đ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            // Items list
                            ...order.items.map((item) {
                              final itemTotal = item.subtotal;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.menuItemName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_formatPrice(item.unitPrice)}đ × ${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatPrice(itemTotal) + 'đ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bottom summary and complete button
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng: $totalItems món',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_formatPrice(totalAmount)}đ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF2E7D32),
                        ),
                        label: const Text(
                          'Đã phục vụ',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        // Enable chỉ khi tất cả order đã hoàn thành và không có order chưa hoàn thành
                        onPressed: (!hasUncompletedOrders && !_isProcessing)
                            ? _onComplete
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
