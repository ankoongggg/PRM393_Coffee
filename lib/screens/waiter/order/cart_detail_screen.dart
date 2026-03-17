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
  // Theme colors based on the HTML template
  static const _bgWarm = Color(0xFFFDF8F6);
  static const _coffee50 = Color(0xFFFDF8F6);
  static const _coffee100 = Color(0xFFF2E8E5);
  static const _coffee200 = Color(0xFFEADDD7);
  static const _coffee600 = Color(0xFF8C634F);
  static const _coffee900 = Color(0xFF4A332D);
  static const _emerald600 = Color(0xFF059669);

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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xác nhận gửi order?', style: TextStyle(color: _coffee900, fontWeight: FontWeight.bold)),
        content: Text(
          'Bàn ${widget.tableNumber}: $_totalItems món\nTổng: ${_formatPrice(_totalPrice)}đ',
          style: const TextStyle(color: _coffee600, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _coffee600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              _processOrderSubmission();
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            backgroundColor: _coffee600,
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
                          Icon(Icons.shopping_cart_outlined, size: 64, color: _coffee200),
                          const SizedBox(height: 16),
                          const Text('Giỏ hàng trống', style: TextStyle(color: _coffee600, fontSize: 16)),
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
                            border: Border.all(color: _coffee100),
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
                                    Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _coffee900), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('${_formatPrice(item.price)}đ', style: const TextStyle(fontSize: 13, color: _emerald600, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              // Nút điều chỉnh số lượng hình dọc
                              Container(
                                decoration: BoxDecoration(
                                  color: _coffee50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _coffee200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 16),
                                      color: _coffee600,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 40),
                                      onPressed: () => _decrement(itemId),
                                    ),
                                    Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _coffee900)),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 16),
                                      color: _coffee600,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 40),
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
                  const Text('GIỎ HÀNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _coffee600, letterSpacing: 0.5)),
                  Text('Bàn ${widget.tableNumber.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _coffee900)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row tính tiền
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
              Text('${_formatPrice(_totalPrice)}đ', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _coffee900)),
            ],
          ),
          const SizedBox(height: 20),
          // Nút xác nhận
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _coffee600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _submitOrder,
              child: const Text('GỬI ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}