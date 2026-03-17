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

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  OrderStatus _batchStatus(OrderModel order, String batchId) {
    final b = batchId.isEmpty ? 'initial' : batchId;
    // Nếu batchStatus chưa có key (data cũ), mặc định coi như pending để tránh
    // việc đổi status tổng làm tất cả card "đổi theo".
    return order.batchStatus[b] ?? OrderStatus.pending;
  }

  List<String> _sortedBatchKeys(OrderModel order) {
    final keys = order.items
        .map((i) => i.batchId.isEmpty ? 'initial' : i.batchId)
        .toSet()
        .toList();
    keys.sort((a, b) {
      if (a == 'initial' && b != 'initial') return -1;
      if (b == 'initial' && a != 'initial') return 1;
      final aTs = int.tryParse(a.startsWith('add_') ? a.substring(4) : a) ?? 0;
      final bTs = int.tryParse(b.startsWith('add_') ? b.substring(4) : b) ?? 0;
      return aTs.compareTo(bTs);
    });
    return keys;
  }

  List<OrderItemModel> _itemsForBatch(OrderModel order, String batchId) {
    final b = batchId.isEmpty ? 'initial' : batchId;
    return order.items.where((i) => (i.batchId.isEmpty ? 'initial' : i.batchId) == b).toList();
  }

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

      // Tự động chuyển batch sang Hoàn thành nếu đã tích hết món của batch khi đang ở tab "Pha"
      final batchId = updatedItems[itemIndex].batchId;
      final batchItems = updatedItems.where((i) => i.batchId == batchId).toList();
      if (_batchStatus(order, batchId) == OrderStatus.preparing &&
          batchItems.isNotEmpty &&
          batchItems.every((item) => item.isDone)) {
        await orderProvider.updateOrderBatchStatus(
          orderId: order.id,
          batchId: batchId,
          status: OrderStatus.completed,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Batch đã hoàn thành!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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

  Future<void> _updateBatchStatus({
    required String orderId,
    required String batchId,
    required OrderStatus newStatus,
    required String message,
    required Color color,
  }) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    try {
      await orderProvider.updateOrderBatchStatus(
        orderId: orderId,
        batchId: batchId,
        status: newStatus,
      );
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

        // Lọc theo batchStatus (mỗi card là 1 batch)
        final pendingEntries = <({OrderModel order, String batchId, int batchIndex, int batchCount})>[];
        final preparingEntries = <({OrderModel order, String batchId, int batchIndex, int batchCount})>[];
        final completedEntries = <({OrderModel order, String batchId, int batchIndex, int batchCount})>[];

        for (final o in allOrders) {
          final keys = _sortedBatchKeys(o);
          for (var i = 0; i < keys.length; i++) {
            final b = keys[i];
            final s = _batchStatus(o, b);
            final entry = (order: o, batchId: b, batchIndex: i, batchCount: keys.length);
            if (s == OrderStatus.pending) pendingEntries.add(entry);
            if (s == OrderStatus.preparing) preparingEntries.add(entry);
            if (s == OrderStatus.completed) completedEntries.add(entry);
          }
        }

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
                Tab(text: '⏳ Chờ (${pendingEntries.length})'),
                Tab(text: '🔄 Pha (${preparingEntries.length})'),
                Tab(text: '✅ Xong (${completedEntries.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildEntryList(pendingEntries, OrderStatus.pending),
              _buildEntryList(preparingEntries, OrderStatus.preparing),
              _buildEntryList(completedEntries, OrderStatus.completed),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntryList(
    List<({OrderModel order, String batchId, int batchIndex, int batchCount})> entries,
    OrderStatus status,
  ) {
    if (entries.isEmpty) return _buildEmptyState(status);
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (_, i) => _buildOrderBatchCard(
        entries[i].order,
        status,
        entries[i].batchId,
        entries[i].batchIndex,
        entries[i].batchCount,
      ),
    );
  }

  Widget _buildOrderBatchCard(
    OrderModel order,
    OrderStatus status,
    String batchId,
    int batchIndex,
    int batchCount,
  ) {
    final batchItems = _itemsForBatch(order, batchId);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        children: [
          _buildBatchHeader(order, status, batchIndex, batchCount),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // ✅ ĐÃ XÓA CHECKBOX - CHỈ HIỂN THỊ DANH SÁCH MÓN
                ...batchItems.map((item) {
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
                      _buildActionButton(order, status, batchId),
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

  Widget _buildBatchHeader(OrderModel order, OrderStatus status, int batchIndex, int batchCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '📋 Bill ${order.id.substring(0, 6).toUpperCase()} • Lần ${(batchIndex + 1).toString().padLeft(2, '0')}/$batchCount',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Waiter: ${order.waiterName}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildActionButton(OrderModel order, OrderStatus status, String batchId) {
    // Nút tại tab CHỜ
    if (status == OrderStatus.pending) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text('BẮT ĐẦU PHA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
        onPressed: () => _updateBatchStatus(
          orderId: order.id,
          batchId: batchId,
          newStatus: OrderStatus.preparing,
          message: 'Đã chuyển batch sang Đang pha',
          color: Colors.blue,
        ),
      );
    }

    // Nút tại tab ĐANG PHA
    if (status == OrderStatus.preparing) {
      final batchItems = _itemsForBatch(order, batchId);
      bool allDone = batchItems.isNotEmpty && batchItems.every((item) => item.isDone);
      return ElevatedButton.icon(
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text('HOÀN THÀNH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        // Nút HOÀN THÀNH chỉ hiện rõ khi đã tích hết món, nếu chưa tích hết sẽ bị mờ nhẹ nhưng vẫn cho bấm nếu bạn muốn
        style: ElevatedButton.styleFrom(
          backgroundColor: allDone ? Colors.green[700] : Colors.grey,
        ),
        onPressed: () => _updateBatchStatus(
          orderId: order.id,
          batchId: batchId,
          newStatus: OrderStatus.completed,
          message: 'Batch đã hoàn thành!',
          color: Colors.green,
        ),
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