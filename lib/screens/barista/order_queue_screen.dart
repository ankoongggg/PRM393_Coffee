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

  // ── NOTIFICATION STATE ──
  final List<_NotificationItem> _notifications = [];
  Set<String> _prevPendingBatchIds = {};
  Set<String> _prevCancelledOrderIds = {};
  bool _isFirstLoad = true;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  OrderStatus _batchStatus(OrderModel order, String batchId) {
    final b = batchId.isEmpty ? 'initial' : batchId;
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
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).startOrderListener();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── DETECT NEW / CANCELLED ORDERS ──
  void _checkForNewNotifications(
    List<({OrderModel order, String batchId, int batchIndex, int batchCount})> pendingEntries,
    List<OrderModel> cancelledOrders,
  ) {
    // Build current IDs
    final currentPendingIds = pendingEntries.map((e) => '${e.order.id}_${e.batchId}').toSet();
    final currentCancelledIds = cancelledOrders.map((o) => o.id).toSet();

    if (_isFirstLoad) {
      // Lần đầu: chỉ ghi nhận, không tạo thông báo
      _prevPendingBatchIds = currentPendingIds;
      _prevCancelledOrderIds = currentCancelledIds;
      _isFirstLoad = false;
      return;
    }

    // Đơn mới (pending batch mới xuất hiện)
    final newPending = currentPendingIds.difference(_prevPendingBatchIds);
    for (final id in newPending) {
      final entry = pendingEntries.firstWhere((e) => '${e.order.id}_${e.batchId}' == id);
      _notifications.insert(0, _NotificationItem(
        type: _NotifType.newOrder,
        message: 'Đơn mới từ ${entry.order.waiterName} - Bàn ${entry.order.tableNumber}',
        time: DateTime.now(),
      ));
    }

    // Đơn bị hủy (cancelled mới xuất hiện)
    final newCancelled = currentCancelledIds.difference(_prevCancelledOrderIds);
    for (final id in newCancelled) {
      final order = cancelledOrders.firstWhere((o) => o.id == id);
      _notifications.insert(0, _NotificationItem(
        type: _NotifType.cancelled,
        message: 'Đơn Bàn ${order.tableNumber} đã bị hủy bởi ${order.waiterName}',
        time: DateTime.now(),
      ));
    }

    // Giới hạn tối đa 50 thông báo
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }

    _prevPendingBatchIds = currentPendingIds;
    _prevCancelledOrderIds = currentCancelledIds;
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _showNotificationPanel() {
    // Đánh dấu tất cả đã đọc
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 56, right: 8),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 340,
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1565C0),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('🔔 Thông báo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('${_notifications.length} mục', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  Flexible(
                    child: _notifications.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('Chưa có thông báo nào', style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _notifications.length,
                            separatorBuilder: (_, __) => Divider(height: 1, indent: 56, color: Colors.grey[100]),
                            itemBuilder: (_, i) {
                              final n = _notifications[i];
                              final isNew = n.type == _NotifType.newOrder;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(color: isNew ? Colors.blue[50] : Colors.red[50], shape: BoxShape.circle),
                                      child: Icon(isNew ? Icons.add_shopping_cart : Icons.cancel_outlined, color: isNew ? Colors.blue : Colors.red, size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(n.message, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 2),
                                          Text(_timeAgo(n.time), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  // ✅ Hàm tích chọn từng món
  void _toggleItemDone(OrderModel order, int itemIndex) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    List<OrderItemModel> updatedItems = List.from(order.items);
    updatedItems[itemIndex].isDone = !updatedItems[itemIndex].isDone;

    try {
      await orderProvider.updateOrderItems(order.id, updatedItems);

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
            const SnackBar(content: Text('✅ Batch đã hoàn thành!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
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
      await orderProvider.updateOrderBatchStatus(orderId: orderId, batchId: batchId, status: newStatus);
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
        final cancelledEntries = <({OrderModel order, String batchId, int batchIndex, int batchCount})>[];
        final cancelledOrders = <OrderModel>[];

        for (final o in allOrders) {
          if (o.status == OrderStatus.cancelled) {
            cancelledOrders.add(o);
            final keys = _sortedBatchKeys(o);
            for (var i = 0; i < keys.length; i++) {
              cancelledEntries.add((order: o, batchId: keys[i], batchIndex: i, batchCount: keys.length));
            }
            continue;
          }

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

        // Detect new notifications (after build data is ready)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final prevCount = _unreadCount;
          _checkForNewNotifications(pendingEntries, cancelledOrders);
          if (_unreadCount != prevCount) {
            setState(() {}); // Trigger badge rebuild
          }
        });

        return Scaffold(
          backgroundColor: const Color(0xFFF0F4FF),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1565C0),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Hàng đợi pha chế', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
              // ── NOTIFICATION BELL ──
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                    onPressed: _showNotificationPanel,
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          _unreadCount > 9 ? '9+' : '$_unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(text: '⏳ Chờ (${pendingEntries.length})'),
                Tab(text: '🔄 Pha (${preparingEntries.length})'),
                Tab(text: '✅ Xong (${completedEntries.length})'),
                Tab(text: '🚫 Hủy (${cancelledEntries.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildEntryList(pendingEntries, OrderStatus.pending),
              _buildEntryList(preparingEntries, OrderStatus.preparing),
              _buildEntryList(completedEntries, OrderStatus.completed),
              _buildEntryList(cancelledEntries, OrderStatus.cancelled),
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
                ...batchItems.map((item) {
                  return ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: status == OrderStatus.cancelled ? Colors.red[50] : Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: status == OrderStatus.cancelled ? Colors.red : Colors.blue,
                        ),
                      ),
                    ),
                    title: Text(
                      item.menuItemName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: status == OrderStatus.cancelled ? TextDecoration.lineThrough : null,
                        color: status == OrderStatus.cancelled ? Colors.grey : null,
                      ),
                    ),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18,
                          color: status == OrderStatus.cancelled ? Colors.red : const Color(0xFF1565C0),
                        ),
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
    if (status == OrderStatus.pending) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text('BẮT ĐẦU PHA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
        onPressed: () => _updateBatchStatus(
          orderId: order.id, batchId: batchId,
          newStatus: OrderStatus.preparing, message: 'Đã chuyển batch sang Đang pha', color: Colors.blue,
        ),
      );
    }

    if (status == OrderStatus.preparing) {
      final batchItems = _itemsForBatch(order, batchId);
      bool allDone = batchItems.isNotEmpty && batchItems.every((item) => item.isDone);
      return ElevatedButton.icon(
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text('HOÀN THÀNH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: allDone ? Colors.green[700] : Colors.grey),
        onPressed: () => _updateBatchStatus(
          orderId: order.id, batchId: batchId,
          newStatus: OrderStatus.completed, message: 'Batch đã hoàn thành!', color: Colors.green,
        ),
      );
    }

    if (status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
        child: const Text('ĐÃ HỦY', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
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
      case OrderStatus.cancelled: return Colors.red;
      default: return Colors.grey;
    }
  }
}

// ── NOTIFICATION MODEL ──
enum _NotifType { newOrder, cancelled }

class _NotificationItem {
  final _NotifType type;
  final String message;
  final DateTime time;
  bool isRead;

  _NotificationItem({
    required this.type,
    required this.message,
    required this.time,
    this.isRead = false,
  });
}