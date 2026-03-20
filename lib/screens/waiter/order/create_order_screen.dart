import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/menu_provider.dart';
import '../../../providers/ingredient_provider.dart'; // ✅ Thêm Provider kho
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
  static const _bgWarm = Color(0xFFFBF9F5);
  static const _coffee100 = Color(0xFFF0EBE6);
  static const _coffee200 = Color(0xFFE4E2DE);
  static const _coffee600 = Color(0xFF504442);
  static const _coffee900 = Color(0xFF361F1A);

  String _selectedCategory = 'Tất cả';
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Đảm bảo dữ liệu menu và kho được nạp
      context.read<MenuProvider>().fetchMenuItems();
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
      } catch (_) {}
    });
    return total;
  }

  String _formatPrice(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ✅ Cập nhật hàm cộng món: Kiểm tra tồn kho trước khi cộng
  void _increment(dynamic item) {
    if ((_cart[item.id] ?? 0) < item.quantity) {
      setState(() => _cart[item.id] = (_cart[item.id] ?? 0) + 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Món ${item.name} đã hết nguyên liệu để làm thêm!'), backgroundColor: Colors.orange),
      );
    }
  }

  void _decrement(String id) => setState(() {
    if ((_cart[id] ?? 0) <= 1) {
      _cart.remove(id);
    } else {
      _cart[id] = _cart[id]! - 1;
    }
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Lắng nghe kho để tính lại số ly có thể phục vụ
    final ingredients = context.watch<IngredientProvider>().ingredients;
    final menuProvider = context.watch<MenuProvider>();

    // Cập nhật quantity động mỗi khi build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ingredients.isNotEmpty) {
        menuProvider.updateAvailableQuantities(ingredients);
      }
    });

    if (menuProvider.isLoading && menuProvider.menuItems.isEmpty) {
      return const Scaffold(backgroundColor: _bgWarm, body: Center(child: CircularProgressIndicator(color: _coffee600)));
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
            Expanded(child: _buildMenuGrid(filteredItems)),
          ],
        ),
      ),
      bottomNavigationBar: _totalItems > 0 ? _buildCartBar() : null,
    );
  }

  // ── HEADER ──
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: _coffee100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_rounded, color: _coffee900), onPressed: () => Navigator.pop(context)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CHỌN MÓN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _coffee900, letterSpacing: 0.5)),
                  Text('Bàn ${widget.tableNumber.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _coffee900)),
                ],
              ),
            ],
          ),
          _buildCartBadge(),
        ],
      ),
    );
  }

  Widget _buildCartBadge() {
    return IconButton(
      onPressed: _goToCart,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_bag_outlined, color: _coffee900),
          if (_totalItems > 0)
            Positioned(
              right: -4, top: -4,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: _coffee900, shape: BoxShape.circle),
                child: Text('$_totalItems', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
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
      color: Colors.white,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? _coffee900 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? _coffee900 : _coffee100),
              ),
              alignment: Alignment.center,
              child: Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? Colors.white : _coffee600)),
            ),
          );
        },
      ),
    );
  }

  // ── MENU GRID ──
  Widget _buildMenuGrid(List items) {
    if (items.isEmpty) return const Center(child: Text('Không tìm thấy món phù hợp'));
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final cartQty = _cart[item.id] ?? 0;
        return _buildItemCard(item, cartQty);
      },
    );
  }

  Widget _buildItemCard(dynamic item, int cartQty) {
    final bool outOfStock = item.quantity <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _coffee100),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: item.imageURL.isNotEmpty // ✅ Đã sửa imageURL hoa
                      ? Image.network(item.imageURL, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildPlaceholder())
                      : _buildPlaceholder(),
                ),
                // Lớp phủ khi hết hàng
                if (outOfStock)
                  Container(
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                    child: const Center(child: Text('HẾT HÀNG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
                  ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(8)),
                    child: Text('CÒN: ${item.quantity}', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: outOfStock ? Colors.red : Colors.green)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _coffee900), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${_formatPrice(item.price)}đ', style: const TextStyle(fontSize: 12, color: Color(0xFF1B6D24), fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                _buildActionButtons(item, cartQty),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic item, int cartQty) {
    if (item.quantity <= 0) return const SizedBox(height: 32, child: Center(child: Text('Tạm ngưng', style: TextStyle(fontSize: 10, color: Colors.grey))));

    if (cartQty == 0) {
      return SizedBox(
        width: double.infinity,
        height: 32,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _bgWarm, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: _coffee100))),
          onPressed: () => _increment(item),
          child: const Text('Thêm +', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _coffee900)),
        ),
      );
    }

    return Container(
      height: 32,
      decoration: BoxDecoration(color: _bgWarm, borderRadius: BorderRadius.circular(10), border: Border.all(color: _coffee100)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.remove_rounded, size: 18), onPressed: () => _decrement(item.id)),
          Text('$cartQty', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.add_rounded, size: 18), onPressed: () => _increment(item)),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() => Container(color: _coffee100, child: const Icon(Icons.local_cafe_rounded, size: 30, color: _coffee200));

  // ── BOTTOM BAR ──
  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.08), blurRadius: 24, offset: Offset(0, -8))]),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_totalItems món đã chọn', style: const TextStyle(fontSize: 11, color: _coffee600, fontWeight: FontWeight.w600)),
              Text('${_formatPrice(_totalPrice)}đ', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _coffee900)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _coffee900, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: _goToCart,
            child: const Text('XEM GIỎ HÀNG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _goToCart() {
    if (_totalItems > 0) {
      Navigator.pushNamed(context, AppRoutes.waiterCartDetail, arguments: {'tableId': widget.tableId, 'tableNumber': widget.tableNumber, 'cartItems': _cart});
    }
  }
}