import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/enums/order_status.dart';
import '../../models/order_model.dart';
import '../../models/order_item_model.dart';
import '../../routes/app_routes.dart';

class OrderQueueScreen extends StatefulWidget {
  const OrderQueueScreen({super.key});

  @override
  State<OrderQueueScreen> createState() => _OrderQueueScreenState();
}

class _OrderQueueScreenState extends State<OrderQueueScreen> {
  // ── THEME FROM STITCH ──
  static const _bgSoft = Color(0xFFFBF9F5);
  static const _coffeeDark = Color(0xFF361F1A);
  static const _coffeeMedium = Color(0xFF504442);
  static const _coffeeLight = Color(0xFFE4E2DE);
  static const _primary = Color(0xFF003A76);
  static const _cardShadow = Color.fromRGBO(54, 31, 26, 0.04);

  // ── STATE ──
  int _selectedTab = 0;
  final List<_NotificationItem> _notifications = [];
  Set<String> _prevPendingBatchIds = {};
  Set<String> _prevCancelledOrderIds = {};
  bool _isFirstLoad = true;

  // ── BATCH HELPERS ──
  OrderStatus _batchStatus(OrderModel order, String batchId) {
    final b = batchId.isEmpty ? 'initial' : batchId;
    return order.batchStatus[b] ?? OrderStatus.pending;
  }

  List<String> _sortedBatchKeys(OrderModel order) {
    final keys = order.items.map((i) => i.batchId.isEmpty ? 'initial' : i.batchId).toSet().toList();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).startOrderListener();
    });
  }

  // ── NOTIFICATIONS ──
  void _checkForNewNotifications(
    List<_BatchEntry> pendingEntries,
    List<OrderModel> cancelledOrders,
  ) {
    final currentPendingIds = pendingEntries.map((e) => '${e.order.id}_${e.batchId}').toSet();
    final currentCancelledIds = cancelledOrders.map((o) => o.id).toSet();

    if (_isFirstLoad) {
      _prevPendingBatchIds = currentPendingIds;
      _prevCancelledOrderIds = currentCancelledIds;
      _isFirstLoad = false;
      return;
    }

    final newPending = currentPendingIds.difference(_prevPendingBatchIds);
    for (final id in newPending) {
      final entry = pendingEntries.firstWhere((e) => '${e.order.id}_${e.batchId}' == id);
      _notifications.insert(0, _NotificationItem(
        type: _NotifType.newOrder,
        message: 'Đơn mới từ ${entry.order.waiterName} - Bàn ${entry.order.tableNumber}',
        time: DateTime.now(),
      ));
    }

    final newCancelled = currentCancelledIds.difference(_prevCancelledOrderIds);
    for (final id in newCancelled) {
      final order = cancelledOrders.firstWhere((o) => o.id == id);
      _notifications.insert(0, _NotificationItem(
        type: _NotifType.cancelled,
        message: 'Đơn Bàn ${order.tableNumber} đã bị hủy bởi ${order.waiterName}',
        time: DateTime.now(),
      ));
    }

    if (_notifications.length > 50) _notifications.removeRange(50, _notifications.length);
    _prevPendingBatchIds = currentPendingIds;
    _prevCancelledOrderIds = currentCancelledIds;
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _showNotificationPopup() {
    setState(() {
      for (final n in _notifications) { n.isRead = true; }
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(color: _primary, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                        ? const Padding(padding: EdgeInsets.all(32), child: Text('Chưa có thông báo', style: TextStyle(color: Colors.grey)))
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
                                  children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(color: isNew ? _primary.withValues(alpha: 0.1) : Colors.red[50], shape: BoxShape.circle),
                                      child: Icon(isNew ? Icons.add_shopping_cart : Icons.cancel_outlined, color: isNew ? _primary : Colors.red, size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(n.message, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        Text(_timeAgo(n.time), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                                      ],
                                    )),
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

  // ── ACTIONS ──
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
          SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName = authProvider.currentUser?.name ?? 'Barista';

    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final allOrders = orderProvider.orders;

        final pendingEntries = <_BatchEntry>[];
        final preparingEntries = <_BatchEntry>[];
        final completedEntries = <_BatchEntry>[];
        final cancelledEntries = <_BatchEntry>[];
        final cancelledOrders = <OrderModel>[];

        for (final o in allOrders) {
          if (o.status == OrderStatus.cancelled) {
            cancelledOrders.add(o);
            final keys = _sortedBatchKeys(o);
            for (var i = 0; i < keys.length; i++) {
              cancelledEntries.add(_BatchEntry(order: o, batchId: keys[i], batchIndex: i, batchCount: keys.length));
            }
            continue;
          }
          final keys = _sortedBatchKeys(o);
          for (var i = 0; i < keys.length; i++) {
            final b = keys[i];
            final s = _batchStatus(o, b);
            final entry = _BatchEntry(order: o, batchId: b, batchIndex: i, batchCount: keys.length);
            if (s == OrderStatus.pending) pendingEntries.add(entry);
            if (s == OrderStatus.preparing) preparingEntries.add(entry);
            if (s == OrderStatus.completed) completedEntries.add(entry);
          }
        }

        // Detect new notifications
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final prevCount = _unreadCount;
          _checkForNewNotifications(pendingEntries, cancelledOrders);
          if (_unreadCount != prevCount) setState(() {});
        });

        final tabEntries = [pendingEntries, preparingEntries, completedEntries, cancelledEntries];
        final tabLabels = ['Chờ', 'Pha', 'Xong', 'Hủy'];
        final tabCounts = tabEntries.map((e) => e.length).toList();
        final currentEntries = tabEntries[_selectedTab];
        final totalToday = pendingEntries.length + preparingEntries.length + completedEntries.length;

        return Scaffold(
          backgroundColor: _bgSoft,
          body: SafeArea(
            child: Column(
              children: [
                // ── HEADER ──
                _buildHeader(userName),
                // ── BODY ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text('Đơn hàng hiện tại', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _coffeeDark)),
                        const SizedBox(height: 4),
                        
                        // Tab pills
                        _buildTabPills(tabLabels, tabCounts),
                        const SizedBox(height: 20),
                        // Order list
                        if (currentEntries.isEmpty)
                          _buildEmptyState()
                        else
                          ...currentEntries.map((e) => _buildOrderCard(e, _tabToStatus(_selectedTab))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  OrderStatus _tabToStatus(int tab) => switch (tab) {
    0 => OrderStatus.pending,
    1 => OrderStatus.preparing,
    2 => OrderStatus.completed,
    3 => OrderStatus.cancelled,
    _ => OrderStatus.pending,
  };

  // ══════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════
  Widget _buildHeader(String userName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF7),
        border: Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: avatar + name
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _primary.withValues(alpha: 0.2), width: 2),
                ),
                child: const Icon(Icons.coffee_maker, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BARISTA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _primary, letterSpacing: 0.5)),
                  Text(userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _coffeeDark)),
                ],
              ),
            ],
          ),
          // Right: notification bell + logout
          Row(
            children: [
              // Bell
              GestureDetector(
                onTap: _showNotificationPopup,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_outlined, color: _coffeeMedium, size: 22),
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 2, top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            _unreadCount > 9 ? '9+' : '$_unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Logout
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded, color: _coffeeMedium, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB PILLS
  // ══════════════════════════════════════════════════════════════
  Widget _buildTabPills(List<String> labels, List<int> counts) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _coffeeLight.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected ? [BoxShadow(color: _primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
                ),
                child: Text(
                  '${labels[i]} (${counts[i]})',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                    color: selected ? Colors.white : _coffeeMedium,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ORDER CARD
  // ══════════════════════════════════════════════════════════════
  Widget _buildOrderCard(_BatchEntry entry, OrderStatus status) {
    final order = entry.order;
    final batchItems = _itemsForBatch(order, entry.batchId);
    final isCancelled = status == OrderStatus.cancelled;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
        boxShadow: const [BoxShadow(color: _cardShadow, blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: Bill + Waiter ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCancelled ? Colors.red.withValues(alpha: 0.05) : _primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Bill #${order.id.substring(0, 6).toUpperCase()} • Lần ${entry.batchIndex + 1}/${entry.batchCount}',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold,
                            color: isCancelled ? Colors.red : _primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Bàn ${order.tableNumber}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _coffeeDark)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Waiter:', style: TextStyle(fontSize: 11, color: _coffeeMedium.withValues(alpha: 0.6))),
                  Text(order.waiterName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _coffeeDark)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Items list ──
          ...batchItems.map((item) => Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _coffeeLight.withValues(alpha: 0.1)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26, height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCancelled ? Colors.red.withValues(alpha: 0.1) : _primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${item.quantity}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isCancelled ? Colors.red : _primary)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.menuItemName,
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: _coffeeDark,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
                if (item.note != null && item.note!.isNotEmpty)
                  Text(item.note!, style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: _coffeeMedium.withValues(alpha: 0.6))),
              ],
            ),
          )),
          const SizedBox(height: 16),
          // ── Action button ──
          _buildActionButton(order, status, entry.batchId, batchItems),
        ],
      ),
    );
  }

  Widget _buildActionButton(OrderModel order, OrderStatus status, String batchId, List<OrderItemModel> batchItems) {
    if (status == OrderStatus.pending) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          onPressed: () => _updateBatchStatus(orderId: order.id, batchId: batchId, newStatus: OrderStatus.preparing, message: 'Đã bắt đầu pha chế!', color: _primary),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('BẮT ĐẦU PHA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
              SizedBox(width: 8),
              Icon(Icons.play_arrow_rounded, size: 20),
            ],
          ),
        ),
      );
    }

    if (status == OrderStatus.preparing) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          onPressed: () => _updateBatchStatus(orderId: order.id, batchId: batchId, newStatus: OrderStatus.completed, message: 'Batch đã hoàn thành!', color: Colors.green),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('HOÀN THÀNH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
              SizedBox(width: 8),
              Icon(Icons.check_rounded, size: 20),
            ],
          ),
        ),
      );
    }

    if (status == OrderStatus.cancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withValues(alpha: 0.15))),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Text('ĐƠN ĐÃ BỊ HỦY', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }

    // Completed
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(16)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
          SizedBox(width: 8),
          Text('ĐÃ HOÀN THÀNH', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ══════════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: Icon(Icons.coffee_outlined, size: 48, color: _primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            Text('Không có đơn nào', style: TextStyle(color: _coffeeMedium.withValues(alpha: 0.4), fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── DATA CLASSES ──
class _BatchEntry {
  final OrderModel order;
  final String batchId;
  final int batchIndex;
  final int batchCount;
  const _BatchEntry({required this.order, required this.batchId, required this.batchIndex, required this.batchCount});
}

enum _NotifType { newOrder, cancelled }

class _NotificationItem {
  final _NotifType type;
  final String message;
  final DateTime time;
  bool isRead = false;
  _NotificationItem({required this.type, required this.message, required this.time});
}