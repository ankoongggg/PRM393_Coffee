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
  static const _bgWarm = Color(0xFFFBF9F5);
  static const _coffee100 = Color(0xFFF0EBE6);
  static const _coffee200 = Color(0xFFE4E2DE);
  static const _coffee600 = Color(0xFF504442);
  static const _coffee900 = Color(0xFF361F1A);
  static const _emerald600 = Color(0xFF1B6D24);
  static const _coffee50 = Color(0xFFFDFBF7);

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
                  const Text('CHỌN MÓN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF361F1A), letterSpacing: 0.5)),
                  Text('Bàn ${widget.tableNumber.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF361F1A))),
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
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: Color(0xFF361F1A), shape: BoxShape.circle),
                      child: Text('$_totalItems', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
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
        border: Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
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
                color: selected ? const Color(0xFF361F1A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? const Color(0xFF361F1A) : const Color(0xFFF0EBE6)),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: selected ? Colors.white : const Color(0xFF504442)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0EBE6)),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                      child: const Text('COFFEE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF361F1A), letterSpacing: 0.5)),
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
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF361F1A)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatPrice(item.price)}đ',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1B6D24), fontWeight: FontWeight.w800),
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
            backgroundColor: const Color(0xFFFBF9F5),
            foregroundColor: const Color(0xFF361F1A),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFF0EBE6))),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Thêm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          onPressed: onIncrement,
        ),
      );
    }

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0EBE6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove_rounded, size: 18, color: Color(0xFF361F1A)),
            onPressed: onDecrement,
          ),
          Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF361F1A))),
          IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF361F1A)),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }



  // ── BOTTOM CART BAR ──
  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.08), blurRadius: 24, offset: Offset(0, -8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFFBF9F5), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF0EBE6))),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_rounded, size: 18, color: Color(0xFF361F1A)),
                const SizedBox(width: 8),
                Text('$_totalItems món', style: const TextStyle(color: Color(0xFF361F1A), fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tạm tính', style: TextStyle(fontSize: 12, color: Color(0xFF504442), fontWeight: FontWeight.w500)),
                Text('${_formatPrice(_totalPrice)}đ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF361F1A))),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF361F1A),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              shadowColor: const Color(0xFF361F1A).withOpacity(0.3),
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
            child: const Text('Tiếp tục', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
