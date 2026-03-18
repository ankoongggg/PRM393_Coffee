import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/order_provider.dart';
import '../../../widgets/date_range_filter_field.dart';

class TableOrdersScreen extends StatefulWidget {
  final String tableId;
  final int tableNumber;
  final int capacity;

  const TableOrdersScreen({
    super.key,
    required this.tableId,
    required this.tableNumber,
    required this.capacity,
  });

  @override
  State<TableOrdersScreen> createState() => _TableOrdersScreenState();
}

class _TableOrdersScreenState extends State<TableOrdersScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final initial = _fromDate ?? _toDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _fromDate = picked;
      if (_toDate != null && _toDate!.isBefore(picked)) {
        _toDate = picked;
      }
    });
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final initial = _toDate ?? _fromDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _toDate = picked;
        if (_fromDate != null && picked.isBefore(_fromDate!)) {
          _fromDate = picked;
        }
      });
    }
  }

  String _formatPrice(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Color _statusColor(String statusString) => switch (statusString) {
    'pending' => const Color(0xFFE67E22),
    'preparing' => const Color(0xFF2980B9),
    'completed' => const Color(0xFF27AE60),
    'cancelled' => Colors.grey,
    _ => Colors.grey,
  };

  String _statusLabel(String statusString) => switch (statusString) {
    'pending' => 'Chờ pha',
    'preparing' => 'Đang pha',
    'completed' => 'Hoàn thành',
    'cancelled' => 'Đã hủy',
    _ => statusString,
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        // Lấy tất cả đơn hàng của bàn này
        final tableOrdersAll = orderProvider.ordersByTable(widget.tableId);
        final tableOrders = (_fromDate == null || _toDate == null)
            ? tableOrdersAll
            : tableOrdersAll
                .where((o) {
                  final start = _startOfDay(_fromDate!);
                  final end = _endOfDay(_toDate!);
                  final t = o.createdAt;
                  return !t.isBefore(start) && !t.isAfter(end);
                })
                .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFFBF9F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBF9F5),
            elevation: 0,
            shape: const Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF361F1A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Bàn ${widget.tableNumber}',
              style: const TextStyle(
                color: Color(0xFF361F1A),
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF361F1A)),
                onPressed: () => orderProvider.startOrderListener(),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.transparent),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
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
              Expanded(
                child: tableOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: const Color(0xFFD4A864).withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        (_fromDate == null || _toDate == null)
                            ? 'Bàn này chưa có đơn hàng'
                            : 'Không có đơn hàng trong khoảng ngày đã chọn',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF9E7B5A).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSummaryCard(tableOrders),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        itemCount: tableOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildOrderCard(tableOrders[i]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(List orders) {
    final totalAmount =
        orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final totalItems =
        orders.fold<int>(0, (sum, o) => sum + (o.items.length as int));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text(
                'Tổng đơn',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF504442),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${orders.length}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF361F1A),
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE8D5C0),
          ),
          Column(
            children: [
              const Text(
                'Tổng món',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF504442),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalItems',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF361F1A),
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE8D5C0),
          ),
          Column(
            children: [
              const Text(
                'Tổng tiền',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF504442),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatPrice(totalAmount)}đ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B6D24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final statusString = order.status.toString().split('.').last;
    final statusColor = _statusColor(statusString);
    
    // Format ngày giờ từ DateTime
    final dateTime = order.createdAt as DateTime;
    final dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.id.substring(0, 8).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF361F1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ngày: $dateStr',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF504442),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Giờ: $timeStr',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF504442),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(statusString),
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0EBE6)),
            const SizedBox(height: 12),
            // Hiển thị các item
            ...order.items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: idx < order.items.length - 1 ? 8 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.menuItemName}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF361F1A),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatPrice(item.unitPrice)}đ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF361F1A),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: const Color(0xFFE8D5C0),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF361F1A),
                  ),
                ),
                Text(
                  '${_formatPrice(order.totalAmount)}đ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B6D24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}
