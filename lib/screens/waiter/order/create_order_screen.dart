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
  // Theme colors consistent with HTML template
  static const _bgWarm = Color(0xFFFDF8F6);
  static const _coffee100 = Color(0xFFF2E8E5);
  static const _coffee200 = Color(0xFFEADDD7);
  static const _coffee600 = Color(0xFF8C634F);
  static const _coffee900 = Color(0xFF4A332D);
  static const _emerald600 = Color(0xFF059669);

  String _selectedCategory = 'Tất cả';
  final Map<String, int> _cart = {}; // itemId → quantity

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        if (menuProvider.isLoading) {
          return const Scaffold(
            backgroundColor: _bgWarm,
            body: Center(child: CircularProgressIndicator(color: _coffee600)),
          );
        }

        if (menuProvider.error != null) {
          return Scaffold(
            backgroundColor: _bgWarm,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('❌ ${menuProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _coffee600, foregroundColor: Colors.white),
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
          backgroundColor: _bgWarm,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildCategoryFilter(categories),
                Expanded(child: _buildMenuGrid(menuProvider, filteredItems)),
              ],
            ),
          ),
          bottomNavigationBar: _totalItems > 0 ? _buildCartBar() : null,
        );
      },
    );
  }

  // ── HEADER TOP NAV ──
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
                  const Text('CHỌN MÓN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _coffee600, letterSpacing: 0.5)),
                  Text('Bàn ${widget.tableNumber.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _coffee900)),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              if (_totalItems == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Giỏ hàng đang trống'), backgroundColor: Colors.orange),
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
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined, color: _coffee900),
                if (_totalItems > 0)
                  Positioned(
                    right: -4, top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: _coffee600, shape: BoxShape.circle),
                      child: Text('$_totalItems', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CATEGORY FILTER ──
  Widget _buildCategoryFilter(List<String> categories) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _coffee100)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _coffee600 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? _coffee600 : _coffee200),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : _coffee600),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── MENU GRID ──
  Widget _buildMenuGrid(MenuProvider menuProvider, List items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, // Cao hơn một chút
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _coffee100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Text(item.category, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _coffee600)),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _coffee900),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatPrice(item.price)}đ',
                          style: const TextStyle(fontSize: 12, color: _emerald600, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    _buildItemActions(qty, onIncrement, onDecrement),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: _coffee100,
      child: const Center(child: Icon(Icons.local_cafe_rounded, size: 40, color: _coffee200)),
    );
  }

  Widget _buildItemActions(int qty, VoidCallback onIncrement, VoidCallback onDecrement) {
    if (qty == 0) {
      return SizedBox(
        width: double.infinity,
        height: 32,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _coffee50, // bg nhạt
            foregroundColor: _coffee600,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Thêm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          onPressed: onIncrement,
        ),
      );
    }

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: _coffee50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _coffee200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove_rounded, size: 16, color: _coffee600),
            onPressed: onDecrement,
          ),
          Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _coffee900)),
          IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add_rounded, size: 16, color: _coffee600),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }

  static const _coffee50 = Color(0xFFFDF8F6);

  // ── BOTTOM CART BAR ──
  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: _coffee100, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_rounded, size: 16, color: _coffee600),
                const SizedBox(width: 6),
                Text('$_totalItems món', style: const TextStyle(color: _coffee600, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tạm tính', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text('${_formatPrice(_totalPrice)}đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _coffee900)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _coffee600,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
               Navigator.pushNamed(
                  context,
                  AppRoutes.waiterCartDetail,
                  arguments: {
                    'tableId': widget.tableId,
                    'tableNumber': widget.tableNumber,
                    'cartItems': _cart,
                  },
                );
            },
            child: const Text('Tiếp tục', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
