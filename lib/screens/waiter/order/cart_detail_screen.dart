import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import các Providers
import '../../../providers/menu_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/table_provider.dart';
import '../../../providers/auth_provider.dart';

// Import các Models
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
  // Theme colors based on the HTML template
  static const _bgWarm = Color(0xFFFBF9F5);
  static const _coffee100 = Color(0xFFF0EBE6);
  static const _coffee200 = Color(0xFFE4E2DE);
  static const _coffee600 = Color(0xFF504442);
  static const _coffee900 = Color(0xFF361F1A);
  static const _emerald600 = Color(0xFF1B6D24);

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
        backgroundColor: const Color(0xFFFBF9F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xác nhận gửi order?', style: TextStyle(color: Color(0xFF361F1A), fontWeight: FontWeight.w800)),
        content: Text(
          'Bàn ${widget.tableNumber}: $_totalItems món\nTổng: ${_formatPrice(_totalPrice)}đ',
          style: const TextStyle(color: Color(0xFF504442), fontSize: 16, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF504442), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF361F1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              _processOrderSubmission();
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
      if (existingOrder != null &&
          existingOrder.status != OrderStatus.completed &&
          existingOrder.status != OrderStatus.cancelled) {
        
        // Cộng dồn
        isSuccess = await orderProvider.addItemsToExistingOrder(
          orderId: existingOrder.id,
          newItems: orderItems,
        );
        if (isSuccess && existingOrder.status == OrderStatus.preparing) {
          await orderProvider.updateOrderStatus(existingOrder.id, OrderStatus.pending);
        }
      } else {
        // Tạo mới
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
            backgroundColor: Color(0xFF361F1A),
            behavior: SnackBarBehavior.floating
          ),
        );
        Navigator.pop(context); // close cart
        Navigator.pop(context); // close menu back to table list
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
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _cart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFFE4E2DE)),
                          const SizedBox(height: 16),
                          const Text('Giỏ hàng trống', style: TextStyle(color: Color(0xFF361F1A), fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _cart.length,
                      itemBuilder: (_, i) {
                        final itemId = _cart.keys.elementAt(i);
                        final quantity = _cart[itemId]!;
                        final item = menuProvider.menuItems.firstWhere((m) => m.id == itemId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF0EBE6)),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              // Hình ảnh thu nhỏ
                              Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  color: _coffee100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: item.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(item.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.local_cafe_rounded, color: _coffee200)),
                                      )
                                    : const Icon(Icons.local_cafe_rounded, color: _coffee200),
                              ),
                              const SizedBox(width: 16),
                              // Thông tin món ăn
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF361F1A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    Text('${_formatPrice(item.price)}đ', style: const TextStyle(fontSize: 13, color: Color(0xFF1B6D24), fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                              // Nút điều chỉnh số lượng hình dọc
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBF9F5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _coffee200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_rounded, size: 18),
                                      color: const Color(0xFF361F1A),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 44),
                                      onPressed: () => _decrement(itemId),
                                    ),
                                    Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF361F1A))),
                                    IconButton(
                                      icon: const Icon(Icons.add_rounded, size: 18),
                                      color: const Color(0xFF361F1A),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 44),
                                      onPressed: () => _increment(itemId),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (_cart.isNotEmpty) _buildBottomBar(),
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
        border: Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
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
                  const Text('GIỎ HÀNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF504442), letterSpacing: 0.5)),
                  Text('Bàn ${widget.tableNumber.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF361F1A))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── BOTTOM SUM BAR ──
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.08), blurRadius: 24, offset: Offset(0, -8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row tính tiền
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng', style: TextStyle(fontSize: 15, color: Color(0xFF504442), fontWeight: FontWeight.w700)),
              Text('${_formatPrice(_totalPrice)}đ', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF361F1A))),
            ],
          ),
          const SizedBox(height: 20),
          // Nút xác nhận
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF361F1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
                shadowColor: const Color(0xFF361F1A).withOpacity(0.3),
              ),
              onPressed: _submitOrder,
              child: const Text('GỬI ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}