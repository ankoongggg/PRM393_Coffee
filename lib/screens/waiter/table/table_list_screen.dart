import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/table_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/enums/order_status.dart';
import '../../../models/order_model.dart';
import '../../../routes/app_routes.dart';
import '../../waiter/order/create_order_screen.dart';
import '../../waiter/order/order_detail_screen.dart';
import '../../waiter/order/served_order_screen.dart';

class TableListScreen extends StatefulWidget {
  const TableListScreen({super.key});

  @override
  State<TableListScreen> createState() => _TableListScreenState();
}

class _TableListScreenState extends State<TableListScreen> {
  // Theme colors
  static const _bgWarm = Color(0xFFFDF8F6);
  static const _coffee100 = Color(0xFFF2E8E5);
  static const _coffee200 = Color(0xFFEADDD7);
  static const _coffee600 = Color(0xFF8C634F);
  static const _coffee900 = Color(0xFF4A332D);
  static const _waiterAccent = Color(0xFFE67E22);

  // Status colors
  static const _emptyColor = Color(0xFF10B981);
  static const _emptyBg = Color(0xFFECFDF5);
  static const _emptyLabelBg = Color(0xFFD1FAE5);
  static const _emptyLabelText = Color(0xFF047857);

  static const _waitingColor = Color(0xFF3B82F6);
  static const _waitingBg = Color(0xFFEFF6FF);
  static const _waitingLabelBg = Color(0xFFDBEAFE);
  static const _waitingLabelText = Color(0xFF1D4ED8);

  static const _servingColor = Color(0xFFEF4444);
  static const _servingBg = Color(0xFFFEF2F2);
  static const _servingLabelBg = Color(0xFFFEE2E2);
  static const _servingLabelText = Color(0xFFB91C1C);

  // ── NOTIFICATION STATE ──
  final List<_WaiterNotification> _notifications = [];
  Set<String> _prevCompletedBatchIds = {};
  Set<String> _prevPendingBatchIds = {};
  bool _isFirstLoad = true;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TableProvider>(context, listen: false).fetchTables();
      Provider.of<OrderProvider>(context, listen: false).startOrderListener();
    });
  }

  // ── NOTIFICATION DETECTION ──
  void _checkNotifications(List<OrderModel> orders) {
    final completedBatchIds = <String>{};
    final pendingBatchIds = <String>{};

    for (final o in orders) {
      if (o.status == OrderStatus.cancelled) continue;
      final batchKeys = o.items.map((i) => i.batchId.isEmpty ? 'initial' : i.batchId).toSet();
      for (final b in batchKeys) {
        final status = o.batchStatus[b] ?? OrderStatus.pending;
        final id = '${o.id}_$b';
        if (status == OrderStatus.completed) completedBatchIds.add(id);
        if (status == OrderStatus.pending) pendingBatchIds.add(id);
      }
    }

    if (_isFirstLoad) {
      _prevCompletedBatchIds = completedBatchIds;
      _prevPendingBatchIds = pendingBatchIds;
      _isFirstLoad = false;
      return;
    }

    // Batch mới completed = Barista pha xong
    final newCompleted = completedBatchIds.difference(_prevCompletedBatchIds);
    for (final id in newCompleted) {
      final orderId = id.split('_').first;
      final order = orders.firstWhere((o) => o.id == orderId, orElse: () => orders.first);
      _notifications.insert(0, _WaiterNotification(
        type: _WNotifType.baristaCompleted,
        message: 'Barista đã pha xong đơn Bàn ${order.tableNumber}',
        time: DateTime.now(),
      ));
    }

    // Đơn pending mới = đã gửi thành công
    final newPending = pendingBatchIds.difference(_prevPendingBatchIds);
    for (final id in newPending) {
      final orderId = id.split('_').first;
      final order = orders.firstWhere((o) => o.id == orderId, orElse: () => orders.first);
      _notifications.insert(0, _WaiterNotification(
        type: _WNotifType.orderSent,
        message: 'Đơn Bàn ${order.tableNumber} đã gửi cho Barista',
        time: DateTime.now(),
      ));
    }

    if (_notifications.length > 50) _notifications.removeRange(50, _notifications.length);
    _prevCompletedBatchIds = completedBatchIds;
    _prevPendingBatchIds = pendingBatchIds;
  }

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
                    decoration: const BoxDecoration(color: _waiterAccent, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                              final isSent = n.type == _WNotifType.orderSent;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        color: isSent ? _waiterAccent.withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isSent ? Icons.send_rounded : Icons.check_circle_rounded,
                                        color: isSent ? _waiterAccent : const Color(0xFF10B981),
                                        size: 16,
                                      ),
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

  void _onTableTap(Map<String, dynamic> table) {
    final status = table['status'] as String;
    if (status == 'available') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CreateOrderScreen(tableId: table['id'], tableNumber: table['number'] as int),
      ));
    } else if (status == 'waiting') {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final tableOrders = orderProvider.ordersByTable(table['id']);
      
      if (tableOrders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có order nào cho bàn này'), backgroundColor: Colors.orange),
        );
        return;
      }

      final order = tableOrders.first;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => OrderDetailScreen(order: order, tableId: table['id'], tableNumber: table['number'] as int),
      ));
    } else if (status == 'occupied') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ServedOrderScreen(tableId: table['id'], tableNumber: table['number'] as int),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bàn ${table['number']} không khả dụng'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TableProvider, OrderProvider>(
      builder: (context, tableProvider, orderProvider, child) {
        final tables = tableProvider.tables;
        final available = tables.where((t) => t.status.toString().split('.').last == 'available').length;
        final occupied = tables.where((t) => t.status.toString().split('.').last == 'occupied').length;
        final waiting = tables.where((t) => t.status.toString().split('.').last == 'waiting').length;

        // Detect notifications
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final prevCount = _unreadCount;
          _checkNotifications(orderProvider.orders);
          if (_unreadCount != prevCount) setState(() {});
        });

        if (tableProvider.isLoading) {
          return const Scaffold(
            backgroundColor: _bgWarm,
            body: Center(child: CircularProgressIndicator(color: _coffee600)),
          );
        }

        if (tableProvider.error != null) {
          return Scaffold(
            backgroundColor: _bgWarm,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('❌ ${tableProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _coffee600, foregroundColor: Colors.white),
                    onPressed: () => tableProvider.fetchTables(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _bgWarm,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusSummary(available, waiting, occupied),
                        const SizedBox(height: 24),
                        _buildGrid(tables),
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

  // ── HEADER TOP NAV ──
  Widget _buildHeader(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName = authProvider.currentUser?.name ?? 'Nhân viên';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: _coffee100)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
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
                  color: _waiterAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _waiterAccent.withValues(alpha: 0.2), width: 2),
                ),
                child: const Icon(Icons.restaurant_menu_rounded, color: _waiterAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WAITER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _waiterAccent, letterSpacing: 0.5)),
                  Text(userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _coffee900)),
                ],
              ),
            ],
          ),
          // Right: bell + logout
          Row(
            children: [
              // Bell
              GestureDetector(
                onTap: _showNotificationPopup,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
                      child: const Icon(Icons.notifications_outlined, color: _coffee600, size: 22),
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 2, top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle,
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
                  child: const Icon(Icons.logout_rounded, color: _coffee600, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── STATUS SUMMARY FILTER ──
  Widget _buildStatusSummary(int available, int waiting, int serving) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _coffee100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSummaryItem(available, 'Trống', _emptyColor),
          Container(width: 1, height: 32, color: _coffee100),
          _buildSummaryItem(waiting, 'Chờ', _waitingColor),
          Container(width: 1, height: 32, color: _coffee100),
          _buildSummaryItem(serving, 'Phục vụ', _servingColor),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(int count, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(count.toString().padLeft(2, '0'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // ── GRID OF TABLES ──
  Widget _buildGrid(List tables) {
    final sortedTables = [...tables];
    sortedTables.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
    
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: sortedTables.length,
      itemBuilder: (_, i) => _buildTableCard(sortedTables[i]),
    );
  }

  Widget _buildTableCard(dynamic tableModel) {
    final statusStr = tableModel.status.toString().split('.').last;
    final isAvailable = statusStr == 'available';
    final isWaiting = statusStr == 'waiting';
    final isOccupied = statusStr == 'occupied';

    Color themeColor = Colors.grey;
    Color bgLight = Colors.grey[100]!;
    Color labelBg = Colors.grey[200]!;
    Color labelText = Colors.grey[700]!;
    String statusLabel = 'Không rõ';
    IconData iconData = Icons.table_bar_rounded;
    String subText = '';

    if (isAvailable) {
      themeColor = _emptyColor; bgLight = _emptyBg; labelBg = _emptyLabelBg; labelText = _emptyLabelText;
      statusLabel = 'Trống'; iconData = Icons.chair_alt_rounded; subText = 'Nhấn để tạo đơn';
    } else if (isWaiting) {
      themeColor = _waitingColor; bgLight = _waitingBg; labelBg = _waitingLabelBg; labelText = _waitingLabelText;
      statusLabel = 'Đang chờ'; iconData = Icons.access_time_filled_rounded; subText = 'Vừa được đặt';
    } else if (isOccupied) {
      themeColor = _servingColor; bgLight = _servingBg; labelBg = _servingLabelBg; labelText = _servingLabelText;
      statusLabel = 'Phục vụ'; iconData = Icons.restaurant_menu_rounded; subText = 'Đang dùng bữa...';
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _onTableTap({
          'id': tableModel.id,
          'number': tableModel.tableNumber,
          'status': statusStr,
        }),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _coffee100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: labelBg, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      statusLabel.toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: labelText, letterSpacing: 0.5),
                    ),
                  ),
                  Text('${tableModel.capacity} chỗ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                ],
              ),
              const Spacer(),
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: bgLight, shape: BoxShape.circle),
                child: Icon(iconData, size: 28, color: themeColor),
              ),
              const SizedBox(height: 12),
              Text(
                'Bàn ${tableModel.tableNumber.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _coffee900),
              ),
              const SizedBox(height: 4),
              Text(
                subText,
                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey[400]),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── NOTIFICATION MODEL ──
enum _WNotifType { orderSent, baristaCompleted }

class _WaiterNotification {
  final _WNotifType type;
  final String message;
  final DateTime time;
  bool isRead;
  _WaiterNotification({required this.type, required this.message, required this.time, this.isRead = false});
}
