import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/table_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/enums/order_status.dart';

class ServedOrderScreen extends StatefulWidget {
  final String tableId;
  final int tableNumber;

  const ServedOrderScreen({
    super.key,
    required this.tableId,
    required this.tableNumber,
  });

  @override
  State<ServedOrderScreen> createState() => _ServedOrderScreenState();
}

class _ServedOrderScreenState extends State<ServedOrderScreen> {
  // Theme colors consistent with HTML template
  static const _bgWarm = Color(0xFFFDF8F6);
  static const _coffee100 = Color(0xFFF2E8E5);
  static const _coffee200 = Color(0xFFEADDD7);
  static const _coffee600 = Color(0xFF8C634F);
  static const _coffee900 = Color(0xFF4A332D);
  static const _emerald600 = Color(0xFF059669);

  bool _isProcessing = false;

  String _formatPrice(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  void _onComplete() async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xác nhận hoàn thành', style: TextStyle(color: _coffee900, fontWeight: FontWeight.bold)),
        content: Text('Bàn ${widget.tableNumber} đã thanh toán?', style: const TextStyle(color: _coffee600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _emerald600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() => _isProcessing = true);
      try {
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        final tableProvider = Provider.of<TableProvider>(context, listen: false);
        
        await tableProvider.setTableAvailable(widget.tableId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Đã cập nhật bàn thành Trống'), backgroundColor: _emerald600),
          );
          Navigator.pop(context); // Trở về TableList
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final tableOrders = orderProvider.ordersByTable(widget.tableId);
        final completedOrders = tableOrders.where((o) => o.status == OrderStatus.completed).toList();
        final hasUncompletedOrders = tableOrders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.preparing).isNotEmpty;
        
        // Màn chờ rỗng (Không có order hoàn thành nào)
        if (completedOrders.isEmpty) {
          return Scaffold(
            backgroundColor: _bgWarm,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_empty_rounded, size: 64, color: Colors.orange[400]),
                          const SizedBox(height: 16),
                          const Text('Chờ Barista hoàn thành...', style: TextStyle(fontSize: 16, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 24),
                          if (hasUncompletedOrders)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 40),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                children: [
                                  const Text('Đơn đang xử lý:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                  const SizedBox(height: 8),
                                  ...tableOrders.where((o) => o.status != OrderStatus.completed).map(
                                    (o) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(o.status == OrderStatus.preparing ? Icons.local_drink : Icons.access_time_rounded, size: 14, color: const Color(0xFFD97706)),
                                          const SizedBox(width: 6),
                                          Text(o.status.displayName.toUpperCase(), style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    )
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final currentOrder = completedOrders.first;
        double totalAmount = currentOrder.totalAmount;
        int totalItems = currentOrder.items.length;

        return Scaffold(
          backgroundColor: _bgWarm,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: 1,
                    itemBuilder: (_, orderIndex) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _coffee100),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header receipt
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(color: _coffee50, shape: BoxShape.circle),
                                    child: const Icon(Icons.receipt_long_rounded, color: _coffee600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('HÓA ĐƠN BÀN ${widget.tableNumber.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _coffee900)),
                                  Text('Mã # ${currentOrder.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: _DashDivider()),
                            // Items list
                            ...currentOrder.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.menuItemName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _coffee900)),
                                          const SizedBox(height: 2),
                                          Text('${item.quantity} × ${_formatPrice(item.unitPrice)}đ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    Text('${_formatPrice(item.subtotal)}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _coffee900)),
                                  ],
                                ),
                              );
                            }),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: _DashDivider()),
                            // Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TỔNG CỘNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _coffee900)),
                                Text('${_formatPrice(totalAmount)}đ', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: _emerald600)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Bottom bar
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Thanh toán', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
                          Text('${_formatPrice(totalAmount)}đ', style: const TextStyle(color: _coffee900, fontWeight: FontWeight.bold, fontSize: 24)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (!hasUncompletedOrders && !_isProcessing) ? _emerald600 : Colors.grey[300],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: (!hasUncompletedOrders && !_isProcessing) ? 4 : 0,
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('XÁC NHẬN ĐÃ THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                          onPressed: (!hasUncompletedOrders && !_isProcessing) ? _onComplete : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── HEADER ──
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _coffee100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _coffee900),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BÀN ĐANG PHỤC VỤ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _emerald600, letterSpacing: 0.5)),
                  Text('Bàn ${widget.tableNumber.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _coffee900)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(20)),
            child: const Text('Phục vụ', style: TextStyle(color: _emerald600, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static const _coffee50 = Color(0xFFFDF8F6);
}

// Custom widget for receipt dotted line
class _DashDivider extends StatelessWidget {
  const _DashDivider();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(width: dashWidth, height: dashHeight, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFEADDD7))));
          }),
        );
      },
    );
  }
}
