import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../core/enums/order_status.dart';

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
    
    // ✅ Fetch pending & preparing orders khi mở screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchAllOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startPreparing(String orderId) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    try {
      // Update status to "preparing"
      await orderProvider.updateOrderStatus(orderId, OrderStatus.preparing);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔄 Bắt đầu pha $orderId'), backgroundColor: Colors.blue),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _completeOrder(String orderId) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    try {
      // Update status to "completed"
      await orderProvider.updateOrderStatus(orderId, OrderStatus.completed);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Hoàn thành $orderId – Thông báo Waiter!'), backgroundColor: const Color(0xFF2E7D32)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF1565C0),
              title: const Text('Hàng đợi pha chế', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final pendingOrders = orderProvider.pendingOrders;
        final preparingOrders = orderProvider.preparingOrders;
        final completedOrders = orderProvider.orders
            .where((o) => o.status == OrderStatus.completed)
            .toList();

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
                Tab(child: Text('⏳ Chờ (${pendingOrders.length})', style: const TextStyle(fontWeight: FontWeight.bold))),
                Tab(child: Text('🔄 Đang pha (${preparingOrders.length})', style: const TextStyle(fontWeight: FontWeight.bold))),
                Tab(child: Text('✅ Đã hoàn thành (${completedOrders.length})', style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(pendingOrders, 'pending'),
              _buildOrderList(preparingOrders, 'preparing'),
              _buildOrderList(completedOrders, 'completed'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderList(List orders, String status) {
    String emptyText = 'Không có dữ liệu';
    IconData emptyIcon = Icons.inbox;
    
    if (status == 'pending') {
      emptyText = 'Không có đơn chờ';
      emptyIcon = Icons.hourglass_empty;
    } else if (status == 'preparing') {
      emptyText = 'Không có đơn đang pha';
      emptyIcon = Icons.local_cafe;
    } else if (status == 'completed') {
      emptyText = 'Không có đơn hoàn thành';
      emptyIcon = Icons.check_circle;
    }
    
    return orders.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(emptyIcon, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  emptyText,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final order = orders[i];
              
              String statusLabel = '⏳ Chờ';
              Color statusColor = Colors.orange;
              
              if (status == 'preparing') {
                statusLabel = '🔄 Pha';
                statusColor = Colors.blue;
              } else if (status == 'completed') {
                statusLabel = '✅ Hoàn thành';
                statusColor = Colors.green;
              }
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📋 ${order.id}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Bàn ${order.tableNumber} - ${order.waiterName}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Items list
                      ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('• ${item.menuItemName}', style: const TextStyle(fontSize: 13)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('×${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      )),
                      if (order.items.isNotEmpty) const SizedBox(height: 12),
                      // Action buttons
                      if (status == 'pending')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () => _startPreparing(order.id),
                            child: const Text('Bắt đầu pha chế', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      else if (status == 'preparing')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () => _completeOrder(order.id),
                            child: const Text('✅ Hoàn thành', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      // For completed orders, show a read-only view (no action button)
                    ],
                  ),
                ),
              );
            },
          );
  }
}
