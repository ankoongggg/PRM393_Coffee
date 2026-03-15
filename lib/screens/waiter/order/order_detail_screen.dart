import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/table_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/enums/order_status.dart';
import '../../../models/order_model.dart';
import './create_order_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  final String tableId;
  final int tableNumber;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.tableId,
    required this.tableNumber,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isProcessing = false;

  double get _totalPrice =>
      widget.order.items.fold(0, (sum, item) => sum + item.subtotal);

  String _formatPrice(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  void _onAddMore() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrderScreen(
          tableId: widget.tableId,
          tableNumber: widget.tableNumber,
        ),
      ),
    );
  }

  void _onServed() async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận phục vụ'),
        content: Text('Bàn ${widget.tableNumber} đã được phục vụ?'),
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
        await tableProvider.setTableOccupied(widget.tableId, widget.order.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã cập nhật sang Đang phục vụ'),
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

  void _onCancelOrder() async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: Text('Bạn có chắc muốn hủy đơn hàng cho bàn ${widget.tableNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Có, hủy đơn',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() => _isProcessing = true);

      try {
        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);
        final tableProvider =
            Provider.of<TableProvider>(context, listen: false);
        
        // Cancel the order
        await orderProvider.updateOrderStatus(
          widget.order.id,
          OrderStatus.cancelled,
        );
        
        // Reset table to available
        await tableProvider.setTableAvailable(widget.tableId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã hủy đơn thành công'),
              backgroundColor: Colors.red,
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
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          // Chỉ hiển thị order hiện tại (1 lần đặt hàng duy nhất)
          final currentOrder = orderProvider.orders.firstWhere(
            (o) => o.id == widget.order.id,
            orElse: () => widget.order,
          );
          
          // Wrap vào list để hiển thị như 1 order
          final tableOrders = [currentOrder];

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: tableOrders.length,
                  itemBuilder: (_, i) {
                    final order = tableOrders[i];
                    final orderTotal = order.items.fold<double>(
                      0,
                      (sum, item) => sum + item.subtotal,
                    );

                    // Determine status label and color
                    String statusLabel = '';
                    Color statusColor = Colors.grey;
                    if (order.status == OrderStatus.pending) {
                      statusLabel = 'Chờ';
                      statusColor = Colors.orange;
                    } else if (order.status == OrderStatus.preparing) {
                      statusLabel = 'Đang pha';
                      statusColor = Colors.blue;
                    } else if (order.status == OrderStatus.completed) {
                      statusLabel = 'Hoàn thành';
                      statusColor = Colors.green;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order header with ID and status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Đơn #${(i + 1).toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            // Items in this order
                            ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.menuItemName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '${_formatPrice(item.unitPrice)}đ × ${item.quantity}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${_formatPrice(item.subtotal)}đ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            // Order total
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${_formatPrice(orderTotal)}đ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bottom summary and action buttons
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
                          'Tổng: ${tableOrders.fold<int>(0, (sum, o) => sum + o.items.length)} món',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_formatPrice(tableOrders.fold<double>(0, (sum, o) => sum + o.items.fold<double>(0, (s, item) => s + item.subtotal)))}đ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Color(0xFF2E7D32),
                            ),
                            label: const Text(
                              'Đặt thêm',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _isProcessing ? null : _onAddMore,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[100],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.close_outlined,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Hủy đơn',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _isProcessing ? null : _onCancelOrder,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            icon: Icon(
                              Icons.check_circle_outline,
                              color: tableOrders.every((o) => o.status == OrderStatus.completed)
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey,
                            ),
                            label: Text(
                              'Đã phục vụ',
                              style: TextStyle(
                                color: tableOrders.every((o) => o.status == OrderStatus.completed)
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Chỉ enable khi TẤT CẢ orders đã hoàn thành
                            onPressed: (tableOrders.isNotEmpty && tableOrders.every((o) => o.status == OrderStatus.completed) && !_isProcessing)
                                ? _onServed
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
