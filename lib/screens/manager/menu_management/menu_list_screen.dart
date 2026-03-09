import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';

class MenuListScreen extends StatefulWidget {
  const MenuListScreen({super.key});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  String _selectedCategory = 'Tất cả';
  final List<String> _categories = ['Tất cả', 'Espresso', 'Latte', 'Cappuccino', 'Cold Brew', 'Frappe'];

  // TODO: thay bằng MenuProvider.menuItems
  final List<Map<String, dynamic>> _mockItems = [
    {'name': 'Espresso Đậm Đà', 'price': 35000, 'category': 'Espresso', 'available': true, 'image': '☕'},
    {'name': 'Caramel Latte', 'price': 55000, 'category': 'Latte', 'available': true, 'image': '🥛'},
    {'name': 'Cappuccino Cổ Điển', 'price': 50000, 'category': 'Cappuccino', 'available': false, 'image': '☁️'},
    {'name': 'Cold Brew Mật Ong', 'price': 60000, 'category': 'Cold Brew', 'available': true, 'image': '🧊'},
    {'name': 'Matcha Frappe', 'price': 65000, 'category': 'Frappe', 'available': true, 'image': '🍵'},
    {'name': 'Vanilla Latte', 'price': 58000, 'category': 'Latte', 'available': true, 'image': '🌼'},
  ];

  List<Map<String, dynamic>> get _filteredItems => _selectedCategory == 'Tất cả'
      ? _mockItems
      : _mockItems.where((e) => e['category'] == _selectedCategory).toList();

  String _formatPrice(int price) =>
      price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F4E37),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quản lý Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {}, // TODO: search
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6F4E37),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm món', style: TextStyle(color: Colors.white)),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.managerMenuAdd),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          _buildSummaryBar(),
          Expanded(child: _buildMenuList()),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF6F4E37) : const Color(0xFFF5EDE0),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF6B4226),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar() {
    final total = _filteredItems.length;
    final available = _filteredItems.where((e) => e['available'] == true).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6F4E37).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _SummaryChip(label: 'Tổng', value: '$total', color: const Color(0xFF6F4E37)),
          const SizedBox(width: 12),
          _SummaryChip(label: 'Có sẵn', value: '$available', color: Colors.green),
          const SizedBox(width: 12),
          _SummaryChip(label: 'Tạm hết', value: '${total - available}', color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Không có món nào', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _filteredItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildMenuCard(_filteredItems[i], i),
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> item, int index) {
    final isAvailable = item['available'] as bool;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1.5,
      shadowColor: const Color(0xFF6F4E37).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Image placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF5EDE0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(item['image'], style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C1A0E))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F4E37).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item['category'],
                            style: const TextStyle(fontSize: 10, color: Color(0xFF6F4E37))),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAvailable ? 'Có sẵn' : 'Tạm hết',
                          style: TextStyle(
                            fontSize: 10,
                            color: isAvailable ? Colors.green[700] : Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatPrice(item['price'])}đ',
                    style: const TextStyle(
                      color: Color(0xFF6F4E37),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                _ActionIconButton(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF1565C0),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.managerMenuEdit,
                    arguments: item,
                  ),
                ),
                const SizedBox(height: 6),
                _ActionIconButton(
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  onTap: () => _confirmDelete(context, item['name']),
                ),
                const SizedBox(height: 6),
                _ActionIconButton(
                  icon: isAvailable ? Icons.toggle_on : Icons.toggle_off_outlined,
                  color: isAvailable ? Colors.green : Colors.grey,
                  onTap: () => setState(() => _mockItems[_mockItems.indexOf(item)]['available'] = !isAvailable),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa món?'),
        content: Text('Bạn có chắc muốn xóa "$name" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // TODO: MenuProvider.deleteMenuItem
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa "$name"'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      );
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      );
}

