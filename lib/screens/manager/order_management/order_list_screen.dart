import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/order_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/firebase_service.dart';
import '../../../widgets/date_range_filter_field.dart';
import '../manager_navigation_bar.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  String _selectedFilter = 'all';
  String _selectedWaiter = 'all'; // Waiter filter
  int _selectedNavIndex = 2; // ORDERS tab
  final _filters = ['all', 'pending', 'preparing', 'completed', 'cancelled'];
  final _filterLabels = {
    'all': 'Tất cả', 'pending': 'Chờ pha', 'preparing': 'Đang pha',
    'completed': 'Hoàn thành', 'cancelled': 'Đã hủy',
  };
  DateTime? _fromDate;
  DateTime? _toDate;
  List<Map<String, dynamic>> _waitersList = [];

  @override
  void initState() {
    super.initState();
    _loadWaiters();
    // ✅ Sử dụng Listener thay vì fetch lẻ để nhận data Real-time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).startOrderListener();
    });
  }

  Future<void> _loadWaiters() async {
    try {
      final users = await FirebaseService().fetchAllUsers();
      if (mounted) {
        setState(() {
          _waitersList = users.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'waiter').toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading waiters: $e');
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  Future<void> _pickRangeCompact() async {
    final range = await showCompactDateRangePickerDialog(
      context,
      initialFrom: _fromDate,
      initialTo: _toDate,
    );
    if (!mounted) return;
    if (range?.startDate == null || range?.endDate == null) return;
    setState(() {
      _fromDate = range!.startDate;
      _toDate = range.endDate;
    });
  }

  List<dynamic> _getFilteredOrders(OrderProvider provider) {
    Iterable<dynamic> result = provider.orders;

    if (_selectedFilter != 'all') {
      result = result.where((o) {
        final st = o.status.toString().split('.').last;
        // Gộp chung đơn "đã phục vụ" vào nhóm "hoàn thành"
        if (_selectedFilter == 'completed' && st == 'served') return true;
        return st == _selectedFilter;
      });
    }

    if (_fromDate != null && _toDate != null) {
      final start = _startOfDay(_fromDate!);
      final end = _endOfDay(_toDate!);
      result = result.where((o) {
        final t = o.createdAt as DateTime;
        return !t.isBefore(start) && !t.isAfter(end);
      });
    }

    if (_selectedWaiter != 'all') {
      // Tìm Object của Waiter đang được select
      final selectedObj = _waitersList.where((w) => w['id'] == _selectedWaiter).firstOrNull;
      final selectedName = selectedObj != null ? selectedObj['name'] : '';

      result = result.where((o) {
        if (o.waiterId == null) return false;
        
        final wid = o.waiterId as String;
        final wname = o.waiterName as String;

        // 1. Trùng khớp chính xác với ID mới trên Firebase
        if (wid == _selectedWaiter) return true;

        // 2. Vá lỗi tương thích dữ liệu cũ (Mock Data)
        // Hệ thống cũ từng dùng 'user_123' (Nguyễn Văn A) và 'user_waiter' (WAITER User)
        // Theo yêu cầu của Manager, toàn bộ đơn cũ này thuộc về tài khoản hiện tại mang tên "Hoàng Minh"
        if (selectedName == 'Hoàng Minh') {
          if (wid == 'user_123' || wid == 'user_waiter' || 
              wname == 'Nguyễn Văn A' || wname == 'WAITER User' || wname == 'Waiter') {
            return true;
          }
        }

        return false;
      });
    }

    return result.toList();
  }

  Color _statusColor(String s) => switch (s) {
    'pending' => const Color(0xFFE67E22),
    'preparing' => const Color(0xFF2980B9),
    'completed' => const Color(0xFF27AE60),
    'served' => const Color(0xFF27AE60), // Gộp chung màu với hoàn thành
    'cancelled' => Colors.grey,
    _ => Colors.grey,
  };

  String _statusLabel(String s) => switch (s) {
    'pending' => 'Chờ pha',
    'preparing' => 'Đang pha',
    'completed' => 'Hoàn thành',
    'served' => 'Hoàn thành', // Gộp chung nhãn với hoàn thành
    'cancelled' => 'Đã hủy',
    _ => s,
  };

  String _formatPrice(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        // Chỉ hiện loading xoay xoay khi danh sách thực sự trống
        if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFFFBF9F5),
              elevation: 0,
              automaticallyImplyLeading: false,
              shape: const Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
              title: const Text('Quản lý Đơn hàng', style: TextStyle(color: Color(0xFF361F1A), fontWeight: FontWeight.w800)),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final filteredOrders = _getFilteredOrders(orderProvider);

        return Scaffold(
          backgroundColor: const Color(0xFFFBF9F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBF9F5),
            elevation: 0,
            automaticallyImplyLeading: false,
            shape: const Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
            title: const Text('Quản lý Đơn hàng', style: TextStyle(color: Color(0xFF361F1A), fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF361F1A)),
                // Nút refresh này sẽ kích hoạt lại listener nếu cần
                onPressed: () => orderProvider.startOrderListener(),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFF361F1A)),
                tooltip: 'Đăng xuất',
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.transparent),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: DateRangeFilterField(
                        fromDate: _fromDate,
                        toDate: _toDate,
                        onTap: _pickRangeCompact,
                        onClear: (_fromDate != null || _toDate != null)
                            ? () => setState(() {
                                  _fromDate = null;
                                  _toDate = null;
                                })
                            : null,
                        placeholder: 'Chọn khoảng ngày',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(height: 30, width: 1, color: const Color(0xFFE4E2DE)),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedWaiter,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E7B5A), size: 20),
                          style: const TextStyle(color: Color(0xFF504442), fontSize: 13, fontWeight: FontWeight.w600),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('Tất cả Waiter', overflow: TextOverflow.ellipsis)),
                            ..._waitersList.map((w) => DropdownMenuItem(value: w['id'] as String, child: Text(w['name'] as String, overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedWaiter = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildFilterBar(),
              _buildSummaryRow(filteredOrders),
              // Hiển thị lỗi nếu có
              if (orderProvider.error != null)
                Text(orderProvider.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              Expanded(child: _buildOrderList(filteredOrders)),
            ],
          ),
          bottomNavigationBar: buildManagerBottomNavigation(
            context: context,
            selectedIndex: _selectedNavIndex,
            onIndexChanged: (index) => setState(() => _selectedNavIndex = index),
          ),
        );
      },
    );
  }

  // ... (Các Widget con bên dưới giữ nguyên như cũ)

  Widget _buildFilterBar() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final selected = f == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF361F1A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE4E2DE)),
              ),
              child: Text(
                _filterLabels[f]!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF504442),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(List<dynamic> orders) {
    final total = orders.fold<double>(0, (s, o) => s + o.totalAmount);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, size: 18, color: Color(0xFF361F1A)),
          const SizedBox(width: 8),
          Text('${orders.length} đơn', style: const TextStyle(fontSize: 14, color: Color(0xFF361F1A), fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('Tổng: ${_formatPrice(total)}đ', style: const TextStyle(fontSize: 14, color: Color(0xFF361F1A), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFD4A864)),
            SizedBox(height: 8),
            Text('Không có đơn hàng', style: TextStyle(color: Color(0xFF9E7B5A))),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildOrderCard(orders[i]),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final statusString = order.status.toString().split('.').last;
    final statusColor = _statusColor(statusString);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pushNamed(context, '/manager/orders/detail', arguments: order.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.receipt, color: statusColor),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Rút gọn ID cho dễ nhìn nếu quá dài
                        Text(order.id.toString().substring(0, 6).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF361F1A))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_statusLabel(statusString), style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.table_bar, size: 14, color: Color(0xFF504442)),
                        const SizedBox(width: 4),
                        Text('Bàn ${order.tableNumber}', style: const TextStyle(fontSize: 12, color: Color(0xFF504442), fontWeight: FontWeight.w500)),
                        const SizedBox(width: 12),
                        const Icon(Icons.person_outline, size: 14, color: Color(0xFF504442)),
                        const SizedBox(width: 4),
                        Text(order.waiterName, style: const TextStyle(fontSize: 12, color: Color(0xFF504442), fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_cafe_outlined, size: 14, color: Color(0xFF504442)),
                        const SizedBox(width: 4),
                        Text('${order.items.length} món', style: const TextStyle(fontSize: 12, color: Color(0xFF504442), fontWeight: FontWeight.w500)),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, size: 14, color: Color(0xFF504442)),
                        const SizedBox(width: 4),
                        Text('${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Color(0xFF504442), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${_formatPrice(order.totalAmount)}đ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF361F1A))),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right, color: Color(0xFF361F1A)),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}