import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/menu_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/table_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/menu_item_model.dart';
import '../../../models/order_item_model.dart';

class CartDetailScreen extends StatefulWidget {
  final String tableId;
  final int tableNumber;
  final Map<String, int> cartItems; // itemId → quantity

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
    // Copy cart để có thể sửa nếu cần
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
      } catch (e) {
        // Item không tìm thấy
      }
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
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 món!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận gửi order?'),
        content: Text('$_totalItems món - Tổng: ${_formatPrice(_totalPrice)}đ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            onPressed: () async {
              Navigator.pop(context); // Đóng dialog
              
              // Lấy user info (waiter) từ AuthProvider
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final waiterId = authProvider.currentUser?.id ?? 'unknown';
              final waiterName = authProvider.currentUser?.name ?? 'Waiter';
              
              // Chuyển cart items thành OrderItemModel list
              final menuProvider = Provider.of<MenuProvider>(context, listen: false);
              final orderItems = <OrderItemModel>[];
              
              _cart.forEach((itemId, quantity) {
                try {
                  final item = menuProvider.menuItems.firstWhere((m) => m.id == itemId);
                  orderItems.add(OrderItemModel(
                    menuItemId: item.id,
                    menuItemName: item.name,
                    unitPrice: item.price,
                    quantity: quantity,
                  ));
                } catch (e) {
                  // Item không tìm thấy
                }
              });
              
              // Gọi OrderProvider để tạo order
              final orderProvider = Provider.of<OrderProvider>(context, listen: false);
              final orderId = await orderProvider.createOrder(
                tableId: widget.tableId,
                tableNumber: widget.tableNumber,
                waiterId: waiterId,
                waiterName: waiterName,
                items: orderItems,
                totalAmount: _totalPrice,
              );
              
              if (orderId != null) {
                // Cập nhật table status thành "waiting"
                final tableProvider = Provider.of<TableProvider>(context, listen: false);
                await tableProvider.setTableWaiting(widget.tableId, orderId);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã gửi order tới Barista!'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                  Navigator.pop(context); // Quay lại CreateOrderScreen
                  Navigator.pop(context); // Quay lại TableListScreen
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Lỗi gửi order!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Gửi order',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF0F9F0),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2E7D32),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Giỏ hàng - Bàn ${widget.tableNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: _cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Giỏ hàng đang trống',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                        ),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        label: const Text(
                          'Quay lại chọn món',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _cart.length,
                        itemBuilder: (_, i) {
                          final itemId = _cart.keys.elementAt(i);
                          final quantity = _cart[itemId]!;

                          MenuItemModel? item;
                          try {
                            item = menuProvider.menuItems
                                .firstWhere((m) => m.id == itemId);
                          } catch (e) {
                            return Container();
                          }

                          final itemTotal = item.price * quantity;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      color: const Color(0xFFF5EDE0),
                                      child: item.imageUrl.isNotEmpty
                                          ? Image.network(
                                              item.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.local_cafe,
                                                size: 30,
                                                color: Color(0xFF2E7D32),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.local_cafe,
                                              size: 30,
                                              color: Color(0xFF2E7D32),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Item info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_formatPrice(item.price)}đ x $quantity = ${_formatPrice(itemTotal)}đ',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF2E7D32),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quantity controls
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _decrement(itemId),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            child: Icon(
                                              Icons.remove,
                                              size: 16,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$quantity',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _increment(itemId),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            child: Icon(
                                              Icons.add,
                                              size: 16,
                                              color: Color(0xFF2E7D32),
                                            ),
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
                      ),
                    ),
                    // Bottom summary and submit button
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tổng: $_totalItems món',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${_formatPrice(_totalPrice)}đ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Color(0xFF2E7D32),
                                  ),
                                  label: const Text(
                                    'Tiếp tục chọn',
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.send,
                                    color: Color(0xFF2E7D32),
                                  ),
                                  label: const Text(
                                    'Gửi order',
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: _submitOrder,
                                ),
                              ),
                            ],
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
}
