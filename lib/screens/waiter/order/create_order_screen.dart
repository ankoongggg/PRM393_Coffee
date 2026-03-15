import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/menu_provider.dart';
import '../../../routes/app_routes.dart';

class CreateOrderScreen extends StatefulWidget {
  final String tableId;
  final int tableNumber;

  const CreateOrderScreen({
    super.key,
    required this.tableId,
    required this.tableNumber,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String _selectedCategory = 'Tất cả';
  final Map<String, int> _cart = {}; // itemId → quantity

  @override
  void initState() {
    super.initState();
    // ✅ Fetch menu items khi mở screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MenuProvider>(context, listen: false).fetchAvailableMenuItems();
    });
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
        // Item không tìm thấy, bỏ qua
      }
    });
    return total;
  }

  String _formatPrice(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

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
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 món!'), backgroundColor: Colors.orange),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận gửi order?'),
        content: Text('$_totalItems món - Tổng: ${_formatPrice(_totalPrice)}đ'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () {
              // TODO: OrderProvider.createOrder()
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã gửi order tới Barista!'),
                  backgroundColor: Color(0xFF2E7D32),
                ),
              );
            },
            child: const Text('Gửi order', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        if (menuProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF2E7D32),
              title: Text('Tạo Order - Bàn ${widget.tableNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (menuProvider.error != null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF2E7D32),
              title: Text('Tạo Order - Bàn ${widget.tableNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('❌ ${menuProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => menuProvider.fetchAvailableMenuItems(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final categories = menuProvider.getCategories();
        final filteredItems = menuProvider.filterByCategory(_selectedCategory);

        return Scaffold(
          backgroundColor: const Color(0xFFF0F9F0),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2E7D32),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Tạo Order - Bàn ${widget.tableNumber}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                      onPressed: () {
                        if (_totalItems == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Giỏ hàng đang trống'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.waiterCartDetail,
                            arguments: {
                              'tableId': widget.tableId,
                              'tableNumber': widget.tableNumber,
                              'cartItems': _cart,
                            },
                          );
                        }
                      },
                    ),
                    if (_totalItems > 0)
                      Positioned(
                        right: 4,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_totalItems',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
      body: Column(
        children: [
          _buildCategoryFilter(categories),
          Expanded(child: _buildMenuGrid(menuProvider, filteredItems)),
        ],
      ),
        );
      },
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2E7D32)),
              ),
              child: Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF2E7D32))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuGrid(MenuProvider menuProvider, List items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final qty = _cart[item.id] ?? 0;
        return _MenuItemCard(
          item: item,
          qty: qty,
          onIncrement: () => _increment(item.id),
          onDecrement: () => _decrement(item.id),
          formatPrice: _formatPrice,
        );
      },
    );
  }

  Widget _MenuItemCard({
    required dynamic item,
    required int qty,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required String Function(double) formatPrice,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large Image Area (expanded to fill space)
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: const Color(0xFFF5EDE0),
              ),
              child: _buildItemImage(item),
            ),
          ),
          // Bottom content (name, price, buttons)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Price
                _buildItemInfo(item, formatPrice),
                const SizedBox(height: 6),
                // Buttons
                _buildItemActions(qty, onIncrement, onDecrement),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(dynamic item) {
    return Stack(
      children: [
        // Image (fills parent)
        item.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Center(child: Icon(Icons.local_cafe, size: 50, color: Color(0xFF2E7D32))),
                ),
              )
            : const Center(child: Icon(Icons.local_cafe, size: 50, color: Color(0xFF2E7D32))),
        // Category Badge
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.category,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemInfo(dynamic item, String Function(double) formatPrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A3C1F)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${formatPrice(item.price)}đ',
          style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildItemActions(int qty, VoidCallback onIncrement, VoidCallback onDecrement) {
    return Row(
      children: [
        // Favorite icon
        SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.favorite_border, size: 16),
            color: Colors.grey[600],
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 4),
        // Quantity or Add button
        if (qty == 0)
          Expanded(
            child: SizedBox(
              height: 28,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: onIncrement,
                child: const Text('+ Thêm', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          )
        else
          Expanded(
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: onDecrement,
                    child: const Icon(Icons.remove, size: 14, color: Color(0xFF2E7D32)),
                  ),
                  Text(
                    '$qty',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2E7D32)),
                  ),
                  GestureDetector(
                    onTap: onIncrement,
                    child: const Icon(Icons.add, size: 14, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCartBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('$_totalItems món', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${_formatPrice(_totalPrice)}đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.send, size: 16, color: Color(0xFF2E7D32)),
            label: const Text('Gửi order', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
            onPressed: _submitOrder,
          ),
        ],
      ),
    );
  }
}
