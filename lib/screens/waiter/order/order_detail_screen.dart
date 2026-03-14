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
          // Lấy order hiện tại từ provider (real-time updates)
          final currentOrder = orderProvider.orders.firstWhere(
            (o) => o.id == widget.order.id,
            orElse: () => widget.order,
          );

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: currentOrder.items.length,
                  itemBuilder: (_, i) {
                    final item = currentOrder.items[i];
                    final itemTotal = item.subtotal;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Item info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.menuItemName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_formatPrice(item.unitPrice)}đ × ${item.quantity} = ${_formatPrice(itemTotal)}đ',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '×${item.quantity}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
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
                          'Tổng: ${currentOrder.items.length} món',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_formatPrice(currentOrder.items.fold<double>(0, (sum, item) => sum + item.subtotal))}đ',
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
                              color: currentOrder.status == OrderStatus.completed
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey,
                            ),
                            label: Text(
                              'Đã phục vụ',
                              style: TextStyle(
                                color: currentOrder.status == OrderStatus.completed
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Chỉ enable khi order đã hoàn thành
                            onPressed: (currentOrder.status == OrderStatus.completed && !_isProcessing)
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
