import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/table_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/enums/order_status.dart';
import '../../../models/order_model.dart';
import './create_order_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  final String tableId;
  final int tableNumber;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.tableId,
    required this.tableNumber,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  // Theme colors consistent with HTML template
  static const _bgWarm = Color(0xFFFDF8F6);
  static const _coffee100 = Color(0xFFF2E8E5);
  static const _coffee200 = Color(0xFFEADDD7);
  static const _coffee600 = Color(0xFF8C634F);
  static const _coffee900 = Color(0xFF4A332D);

  bool _isProcessing = false;

  double get _totalPrice =>
      widget.order.items.fold(0, (sum, item) => sum + item.subtotal);

  String _formatPrice(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  void _onAddMore() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrderScreen(
          tableId: widget.tableId,
          tableNumber: widget.tableNumber,
        ),
      ),
    );
  }

  void _onServed() async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xác nhận phục vụ', style: TextStyle(color: _coffee900, fontWeight: FontWeight.bold)),
        content: Text('Bàn ${widget.tableNumber} đã được phục vụ?', style: const TextStyle(color: _coffee600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _coffee600,
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
        final tableProvider = Provider.of<TableProvider>(context, listen: false);
        await tableProvider.setTableOccupied(widget.tableId, widget.order.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Đã cập nhật sang Đang phục vụ'), backgroundColor: _coffee600),
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

  void _onCancelOrder() async {
    if (_isProcessing) return;

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    OrderModel? latestOrder;
    try {
      latestOrder = orderProvider.orders.firstWhere((o) => o.id == widget.order.id);
    } catch (_) {
      latestOrder = null;
    }

    final status = (latestOrder ?? widget.order).status;
    final cannotCancel = status == OrderStatus.completed ||
        status == OrderStatus.served ||
        status == OrderStatus.cancelled;

    if (cannotCancel) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Không thể hủy đơn khi trạng thái là: ${status.displayName}'), backgroundColor: Colors.orange),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xác nhận hủy đơn', style: TextStyle(color: _coffee900, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn hủy đơn hàng cho bàn ${widget.tableNumber}?', style: const TextStyle(color: _coffee600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có, hủy đơn', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() => _isProcessing = true);
      try {
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        final tableProvider = Provider.of<TableProvider>(context, listen: false);
        
        await orderProvider.updateOrderStatus(widget.order.id, OrderStatus.cancelled);
        await tableProvider.setTableAvailable(widget.tableId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Đã hủy đơn thành công'), backgroundColor: Colors.red),
          );
          Navigator.pop(context);
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
    return Scaffold(
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer<OrderProvider>(
                builder: (context, orderProvider, _) {
                  final currentOrder = orderProvider.orders.firstWhere(
                    (o) => o.id == widget.order.id,
                    orElse: () => widget.order,
                  );
                  
                  final cannotCancel = currentOrder.status == OrderStatus.completed ||
                      currentOrder.status == OrderStatus.served ||
                      currentOrder.status == OrderStatus.cancelled;

                  final Map<String, List<dynamic>> itemsByBatch = {};
                  for (final item in currentOrder.items) {
                    final batchId = (item.batchId.isEmpty) ? 'initial' : item.batchId;
                    (itemsByBatch[batchId] ??= []).add(item);
                  }
                  final batchKeys = itemsByBatch.keys.toList()
                    ..sort((a, b) {
                      if (a == 'initial' && b != 'initial') return -1;
                      if (b == 'initial' && a != 'initial') return 1;
                      final aTs = int.tryParse(a.startsWith('add_') ? a.substring(4) : a) ?? 0;
                      final bTs = int.tryParse(b.startsWith('add_') ? b.substring(4) : b) ?? 0;
                      return aTs.compareTo(bTs);
                    });

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: batchKeys.length,
                          itemBuilder: (_, i) {
                            final batchId = batchKeys[i];
                            final batchItems = itemsByBatch[batchId]!;
                            final orderTotal = batchItems.fold<double>(0, (sum, item) => sum + item.subtotal);

                            final batchStatus = currentOrder.batchStatus[batchId] ?? OrderStatus.pending;
                            String statusLabel = '';
                            Color statusColor = Colors.grey;
                            Color statusBg = Colors.grey[100]!;
                            if (batchStatus == OrderStatus.pending) {
                              statusLabel = 'Chờ'; statusColor = const Color(0xFFD97706); statusBg = const Color(0xFFFEF3C7);
                            } else if (batchStatus == OrderStatus.preparing) {
                              statusLabel = 'Đang pha'; statusColor = const Color(0xFF2563EB); statusBg = const Color(0xFFDBEAFE);
                            } else if (batchStatus == OrderStatus.completed) {
                              statusLabel = 'Hoàn thành'; statusColor = const Color(0xFF059669); statusBg = const Color(0xFFD1FAE5);
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _coffee100),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Order header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Mã Bill #${widget.order.id.substring(0, 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _coffee900)),
                                          Text('Lần ${(i + 1).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                                        child: Text(statusLabel.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(height: 1, color: _coffee100),
                                  ),
                                  // Items
                                  ...batchItems.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.menuItemName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _coffee900)),
                                              const SizedBox(height: 2),
                                              Text('${_formatPrice(item.unitPrice)}đ × ${item.quantity}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                        Text('${_formatPrice(item.subtotal)}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _coffee600)),
                                      ],
                                    ),
                                  )),
                                  // Batch Total
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Divider(height: 1, color: _coffee100),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Thành tiền', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                                      Text('${_formatPrice(orderTotal)}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _coffee900)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Bottom bar
                      _buildBottomActions([currentOrder], cannotCancel),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: _coffee900),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CHI TIẾT ĐƠN ĐANG CHỜ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _coffee600, letterSpacing: 0.5)),
              Text('Bàn ${widget.tableNumber.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _coffee900)),
            ],
          ),
        ],
      ),
    );
  }

  // ── BOTTOM ACTIONS ──
  Widget _buildBottomActions(List<OrderModel> tableOrders, bool cannotCancel) {
    if (tableOrders.isEmpty) return const SizedBox.shrink();
    
    final totalItems = tableOrders.fold<int>(0, (sum, o) => sum + o.items.length);
    final totalPrice = tableOrders.fold<double>(0, (sum, o) => sum + o.items.fold<double>(0, (s, item) => s + item.subtotal));
    final isAllCompleted = tableOrders.every((o) => o.status == OrderStatus.completed);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng cộng', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('$totalItems món', style: const TextStyle(color: _coffee600, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Text('${_formatPrice(totalPrice)}đ', style: const TextStyle(color: _coffee900, fontWeight: FontWeight.bold, fontSize: 22)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Nút Đặt thêm
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _coffee50,
                    foregroundColor: _coffee600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isProcessing ? null : _onAddMore,
                  child: const Text('+ Thêm món', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              // Nút Hủy
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: (_isProcessing || cannotCancel) ? null : _onCancelOrder,
                  child: const Text('Hủy đơn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              // Nút Phục vụ
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAllCompleted ? const Color(0xFF059669) : Colors.grey[300],
                    foregroundColor: Colors.white,
                    elevation: isAllCompleted ? 2 : 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Đã phục vụ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: (isAllCompleted && !_isProcessing) ? _onServed : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _coffee50 = Color(0xFFFDF8F6);
}
