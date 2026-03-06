import 'package:flutter/material.dart';

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
  // TODO: replace with MenuProvider.menuItems (available only)
  final List<Map<String, dynamic>> _menuItems = [
    {'id': 'm1', 'name': 'Cà phê sữa đá', 'category': 'Cà phê', 'price': 35000},
    {'id': 'm2', 'name': 'Cà phê đen', 'category': 'Cà phê', 'price': 25000},
    {'id': 'm3', 'name': 'Bạc xỉu', 'category': 'Cà phê', 'price': 30000},
    {'id': 'm4', 'name': 'Matcha latte', 'category': 'Trà', 'price': 45000},
    {'id': 'm5', 'name': 'Trà đào', 'category': 'Trà', 'price': 40000},
    {'id': 'm6', 'name': 'Bánh croissant', 'category': 'Bánh', 'price': 25000},
    {'id': 'm7', 'name': 'Bánh tiramisu', 'category': 'Bánh', 'price': 35000},
  ];

  final Map<String, int> _cart = {}; // itemId → quantity
  String _selectedCategory = 'Tất cả';

  List<String> get _categories => ['Tất cả', ...{for (var m in _menuItems) m['category'] as String}];

  List<Map<String, dynamic>> get _filtered =>
      _selectedCategory == 'Tất cả' ? _menuItems : _menuItems.where((m) => m['category'] == _selectedCategory).toList();

  int get _totalItems => _cart.values.fold(0, (s, q) => s + q);
  int get _totalPrice => _cart.entries.fold(0, (s, e) {
    final item = _menuItems.firstWhere((m) => m['id'] == e.key);
    return s + (item['price'] as int) * e.value;
  });

  String _formatPrice(int amount) =>
      amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Tạo Order - Bàn ${widget.tableNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(child: _buildMenuGrid()),
          if (_totalItems > 0) _buildCartBar(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
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

  Widget _buildMenuGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final item = _filtered[i];
        final qty = _cart[item['id']] ?? 0;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_cafe, size: 18, color: Color(0xFF2E7D32)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                      child: Text(item['category'], style: const TextStyle(fontSize: 9, color: Color(0xFF2E7D32))),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A3C1F)), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${_formatPrice(item['price'] as int)}đ', style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                const Spacer(),
                if (qty == 0)
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () => _increment(item['id'] as String),
                      child: const Text('+ Thêm', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _QtyButton(icon: Icons.remove, onTap: () => _decrement(item['id'] as String)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E7D32))),
                      ),
                      _QtyButton(icon: Icons.add, onTap: () => _increment(item['id'] as String), positive: true),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
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

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool positive;
  const _QtyButton({required this.icon, required this.onTap, this.positive = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: positive ? const Color(0xFF2E7D32) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: positive ? Colors.white : const Color(0xFF2E7D32)),
    ),
  );
}
