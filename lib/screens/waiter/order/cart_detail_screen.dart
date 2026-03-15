import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import các Providers
import '../../../providers/menu_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/table_provider.dart';
import '../../../providers/auth_provider.dart';

// Import các Models
import '../../../models/menu_item_model.dart';
import '../../../models/order_item_model.dart';
import '../../../models/order_model.dart';
import '../../../core/enums/order_status.dart';

class CartDetailScreen extends StatefulWidget {
  final String tableId;
  final int tableNumber;
  final Map<String, int> cartItems;

  const CartDetailScreen({
    super.key,
    required this.tableId,
    required this.tableNumber,
    required this.cartItems,
  });

  @override
  State<CartDetailScreen> createState() => _CartDetailScreenState();
}

class _CartDetailScreenState extends State<CartDetailScreen> {
  late Map<String, int> _cart;

  @override
  void initState() {
    super.initState();
    _cart = Map.from(widget.cartItems);
  }

  int get _totalItems => _cart.values.fold(0, (s, q) => s + q);

  double get _totalPrice {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    double total = 0;
    _cart.forEach((itemId, quantity) {
      try {
        final item = menuProvider.menuItems.firstWhere((m) => m.id == itemId);
        total += item.price * quantity;
      } catch (_) {}
    });
    return total;
  }

  String _formatPrice(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  void _increment(String id) => setState(() => _cart[id] = (_cart[id] ?? 0) + 1);

  void _decrement(String id) => setState(() {
    if ((_cart[id] ?? 0) <= 1) {
      _cart.remove(id);
    } else {
      _cart[id] = _cart[id]! - 1;
    }
  });

  void _submitOrder() {
    if (_cart.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Xác nhận gửi order?'),
        content: Text('Bàn ${widget.tableNumber}: $_totalItems món\nTổng: ${_formatPrice(_totalPrice)}đ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              _processOrderSubmission();
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _processOrderSubmission() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final tableProvider = Provider.of<TableProvider>(context, listen: false);

    // 1. Chuyển đổi sang List OrderItemModel
    final orderItems = <OrderItemModel>[];
    _cart.forEach((itemId, quantity) {
      try {
        final item = menuProvider.menuItems.firstWhere((m) => m.id == itemId);
        orderItems.add(OrderItemModel(
          menuItemId: item.id,
          menuItemName: item.name,
          unitPrice: item.price,
          quantity: quantity,
          isDone: false,
        ));
      } catch (_) {}
    });

    // 2. Tìm đơn hàng hiện tại của bàn
    final currentTable = tableProvider.tables.firstWhere((t) => t.id == widget.tableId);
    String? existingOrderId = currentTable.currentOrderId;

    // Lấy chi tiết đơn hàng để check status
    OrderModel? existingOrder;
    if (existingOrderId != null && existingOrderId.isNotEmpty) {
      try {
        existingOrder = orderProvider.orders.firstWhere((o) => o.id == existingOrderId);
      } catch (_) {
        existingOrder = null;
      }
    }

    bool isSuccess = false;

    try {
      // ✅ LOGIC CHỐNG BỊP TIỀN: Chỉ cộng dồn nếu đơn đang "Mở"
      if (existingOrder != null &&
          existingOrder.status != OrderStatus.completed &&
          existingOrder.status != OrderStatus.cancelled) {

        // TRƯỜNG HỢP 1: Cộng dồn vào đơn hiện có
        isSuccess = await orderProvider.addItemsToExistingOrder(
          orderId: existingOrder.id,
          newItems: orderItems,
        );

        // Đẩy về 'pending' nếu đang 'preparing' để Barista thấy món mới
        if (isSuccess && existingOrder.status == OrderStatus.preparing) {
          await orderProvider.updateOrderStatus(existingOrder.id, OrderStatus.pending);
        }
      } else {
        // TRƯỜNG HỢP 2: Tạo đơn mới (Vì đơn cũ đã chốt hoặc bàn trống)
        final newId = await orderProvider.createOrder(
          tableId: widget.tableId,
          tableNumber: widget.tableNumber,
          waiterId: authProvider.currentUser?.id ?? 'unknown',
          waiterName: authProvider.currentUser?.name ?? 'Waiter',
          items: orderItems,
          totalAmount: _totalPrice,
        );
        if (newId != null) {
          await tableProvider.setTableWaiting(widget.tableId, newId);
          isSuccess = true;
        }
      }

      if (isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Đã gửi đơn hàng thành công!'),
              backgroundColor: Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating
          ),
        );
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: Text('Giỏ hàng - Bàn ${widget.tableNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cart.isEmpty
          ? const Center(child: Text('Giỏ hàng trống'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _cart.length,
              itemBuilder: (_, i) {
                final itemId = _cart.keys.elementAt(i);
                final quantity = _cart[itemId]!;
                final item = menuProvider.menuItems.firstWhere((m) => m.id == itemId);

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.local_cafe, color: Color(0xFF2E7D32)),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${_formatPrice(item.price)}đ', style: const TextStyle(color: Color(0xFF2E7D32))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _decrement(itemId)),
                        Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: () => _increment(itemId)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${_formatPrice(_totalPrice)}đ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: _submitOrder,
              child: const Text('GỬI ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}