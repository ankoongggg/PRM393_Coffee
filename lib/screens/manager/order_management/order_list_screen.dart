import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/order_provider.dart';
import '../../../widgets/date_range_filter_field.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  String _selectedFilter = 'all';
  final _filters = ['all', 'pending', 'preparing', 'completed', 'cancelled'];
  final _filterLabels = {
    'all': 'Tất cả', 'pending': 'Chờ pha', 'preparing': 'Đang pha',
    'completed': 'Xong', 'cancelled': 'Đã hủy',
  };
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    // ✅ Sử dụng Listener thay vì fetch lẻ để nhận data Real-time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).startOrderListener();
    });
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
      result = result.where((o) =>
          o.status.toString().split('.').last == _selectedFilter);
    }

    if (_fromDate != null && _toDate != null) {
      final start = _startOfDay(_fromDate!);
      final end = _endOfDay(_toDate!);
      result = result.where((o) {
        final t = o.createdAt as DateTime;
        return !t.isBefore(start) && !t.isAfter(end);
      });
    }

    return result.toList();
  }

  Color _statusColor(String s) => switch (s) {
    'pending' => const Color(0xFFE67E22),
    'preparing' => const Color(0xFF2980B9),
    'completed' => const Color(0xFF27AE60),
    'cancelled' => Colors.grey,
    _ => Colors.grey,
  };

  String _statusLabel(String s) => switch (s) {
    'pending' => 'Chờ pha',
    'preparing' => 'Đang pha',
    'completed' => 'Hoàn thành',
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
              backgroundColor: const Color(0xFF6F4E37),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Quản lý Đơn hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final filteredOrders = _getFilteredOrders(orderProvider);

        return Scaffold(
          backgroundColor: const Color(0xFFFAF6F1),
          appBar: AppBar(
            backgroundColor: const Color(0xFF6F4E37),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Quản lý Đơn hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                // Nút refresh này sẽ kích hoạt lại listener nếu cần
                onPressed: () => orderProvider.startOrderListener(),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                ),
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
              _buildFilterBar(),
              _buildSummaryRow(filteredOrders),
              // Hiển thị lỗi nếu có
              if (orderProvider.error != null)
                Text(orderProvider.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              Expanded(child: _buildOrderList(filteredOrders)),
            ],
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF6F4E37) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6F4E37)),
              ),
              child: Text(
                _filterLabels[f]!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF6F4E37),
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
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, size: 16, color: Color(0xFF9E7B5A)),
          const SizedBox(width: 6),
          Text('${orders.length} đơn', style: const TextStyle(fontSize: 13, color: Color(0xFF6F4E37), fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('Tổng: ${_formatPrice(total)}đ', style: const TextStyle(fontSize: 13, color: Color(0xFF6F4E37), fontWeight: FontWeight.w600)),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, '/manager/orders/detail', arguments: order.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                        Text(order.id.toString().substring(0, 6).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C1A0E))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_statusLabel(statusString), style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.table_bar, size: 12, color: Color(0xFF9E7B5A)),
                        const SizedBox(width: 3),
                        Text('Bàn ${order.tableNumber}', style: const TextStyle(fontSize: 12, color: Color(0xFF9E7B5A))),
                        const SizedBox(width: 10),
                        const Icon(Icons.person_outline, size: 12, color: Color(0xFF9E7B5A)),
                        const SizedBox(width: 3),
                        Text(order.waiterName, style: const TextStyle(fontSize: 12, color: Color(0xFF9E7B5A))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.local_cafe_outlined, size: 12, color: Color(0xFF9E7B5A)),
                        const SizedBox(width: 3),
                        Text('${order.items.length} món', style: const TextStyle(fontSize: 12, color: Color(0xFF9E7B5A))),
                        const SizedBox(width: 10),
                        const Icon(Icons.access_time, size: 12, color: Color(0xFF9E7B5A)),
                        const SizedBox(width: 3),
                        Text('${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Color(0xFF9E7B5A))),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${_formatPrice(order.totalAmount)}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6F4E37))),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right, color: Color(0xFFD4A864)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}