import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../core/enums/order_status.dart';
import '../../models/order_model.dart';
import '../../models/order_item_model.dart';

class OrderQueueScreen extends StatefulWidget {
  const OrderQueueScreen({super.key});

  @override
  State<OrderQueueScreen> createState() => _OrderQueueScreenState();
}

class _OrderQueueScreenState extends State<OrderQueueScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).startOrderListener();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Hàm tích chọn từng món
  void _toggleItemDone(OrderModel order, int itemIndex) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    List<OrderItemModel> updatedItems = List.from(order.items);
    updatedItems[itemIndex].isDone = !updatedItems[itemIndex].isDone;

    try {
      await orderProvider.updateOrderItems(order.id, updatedItems);

      // Tự động chuyển sang Hoàn thành nếu đã tích hết món khi đang ở tab "Pha"
      if (order.status == OrderStatus.preparing && updatedItems.every((item) => item.isDone)) {
        _updateOrderStatus(order.id, OrderStatus.completed, 'Đã xong toàn bộ món!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ Hàm cập nhật trạng thái đơn hàng (Bấm nút)
  void _updateOrderStatus(String orderId, OrderStatus newStatus, String message, Color color) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    try {
      await orderProvider.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final allOrders = orderProvider.orders;

        // SỬA LẠI LOGIC LỌC: Chỉ lọc theo Status của Order
        final pendingOrders = allOrders.where((o) => o.status == OrderStatus.pending).toList();
        final preparingOrders = allOrders.where((o) => o.status == OrderStatus.preparing).toList();
        final completedOrders = allOrders.where((o) => o.status == OrderStatus.completed).toList();

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
                Tab(text: '⏳ Chờ (${pendingOrders.length})'),
                Tab(text: '🔄 Pha (${preparingOrders.length})'),
                Tab(text: '✅ Xong (${completedOrders.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(pendingOrders, OrderStatus.pending),
              _buildOrderList(preparingOrders, OrderStatus.preparing),
              _buildOrderList(completedOrders, OrderStatus.completed),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, OrderStatus status) {
    if (orders.isEmpty) return _buildEmptyState(status);
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, i) => _buildOrderCard(orders[i], status),
    );
  }

  Widget _buildOrderCard(OrderModel order, OrderStatus status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        children: [
          _buildCardHeader(order, status),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // ✅ ĐÃ XÓA CHECKBOX - CHỈ HIỂN THỊ DANH SÁCH MÓN
                ...order.items.map((item) {
                  return ListTile(
                    dense: true, // Làm cho dòng gọn hơn
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    title: Text(
                      item.menuItemName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Hiển thị note nếu có
                    subtitle: item.note != null && item.note!.isNotEmpty
                        ? Text('Ghi chú: ${item.note}', style: const TextStyle(color: Colors.red, fontSize: 12))
                        : null,
                  );
                }),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bàn ${order.tableNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1565C0)),
                      ),
                      _buildActionButton(order, status),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(OrderModel order, OrderStatus status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('📋 #${order.id.substring(order.id.length > 5 ? order.id.length - 5 : 0)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Waiter: ${order.waiterName}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildActionButton(OrderModel order, OrderStatus status) {
    // Nút tại tab CHỜ
    if (status == OrderStatus.pending) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text('BẮT ĐẦU PHA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
        onPressed: () => _updateOrderStatus(order.id, OrderStatus.preparing, 'Đã chuyển sang Đang pha', Colors.blue),
      );
    }

    // Nút tại tab ĐANG PHA
    if (status == OrderStatus.preparing) {
      bool allDone = order.items.every((item) => item.isDone);
      return ElevatedButton.icon(
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text('HOÀN THÀNH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        // Nút HOÀN THÀNH chỉ hiện rõ khi đã tích hết món, nếu chưa tích hết sẽ bị mờ nhẹ nhưng vẫn cho bấm nếu bạn muốn
        style: ElevatedButton.styleFrom(
          backgroundColor: allDone ? Colors.green[700] : Colors.grey,
        ),
        onPressed: () => _updateOrderStatus(order.id, OrderStatus.completed, 'Đơn hàng đã hoàn thành!', Colors.green),
      );
    }

    return const Icon(Icons.check_circle, color: Colors.green);
  }

  Widget _buildEmptyState(OrderStatus status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_cafe_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Hiện tại không có đơn hàng nào', style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.preparing: return Colors.blue;
      case OrderStatus.completed: return Colors.green;
      default: return Colors.grey;
    }
  }
}