import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../routes/app_routes.dart';
import '../../../providers/menu_provider.dart';
import '../../../models/menu_item_model.dart';

class MenuListScreen extends StatefulWidget {
  const MenuListScreen({super.key});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MenuProvider>(context, listen: false).startMenuListener();
    });
  }

  List<MenuItemModel> _getFilteredItems(MenuProvider provider) {
    if (_selectedCategory == 'Tất cả') {
      return provider.menuItems;
    }
    return provider.menuItems
        .where((item) => item.category == _selectedCategory)
        .toList();
  }

  String _formatPrice(double price) => price
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        final categories = menuProvider.getCategories();
        final filteredItems = _getFilteredItems(menuProvider);

        return Scaffold(
          backgroundColor: const Color(0xFFFAF6F1),
          appBar: AppBar(
            backgroundColor: const Color(0xFF6F4E37),
            elevation: 0,
            // Xóa leading Navigator.pop vì trang này nằm trong Wrapper/IndexedStack
            automaticallyImplyLeading: false,
            title: const Text(
              'Quản lý thực đơn',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => menuProvider.fetchMenuItems(),
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
              _buildCategoryFilter(categories),
              _buildSummaryBar(filteredItems),
              if (menuProvider.isLoading && filteredItems.isEmpty)
                const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF6F4E37))))
              else
                Expanded(child: _buildMenuList(filteredItems)),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildCategoryFilter(List<String> categories) {
    // Đảm bảo không bị lặp 'Tất cả' nếu trong list đã có
    final cleanCategories = categories.where((c) => c != 'Tất cả').toList();
    final allCategories = ['Tất cả', ...cleanCategories];

    return Container(
      color: Colors.white,
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: allCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final cat = allCategories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF6F4E37) : const Color(0xFFF5EDE0),
                borderRadius: BorderRadius.circular(25),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF6B4226),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar(List<MenuItemModel> items) {
    final total = items.length;
    final available = items.where((item) => item.isAvailable).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6F4E37).withValues(alpha: 0.08), // ✅ Đã sửa withOpacity
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SummaryChip(label: 'Tổng', value: '$total', color: const Color(0xFF6F4E37)),
          _SummaryChip(label: 'Có sẵn', value: '$available', color: Colors.green),
          _SummaryChip(label: 'Tạm hết', value: '${total - available}', color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildMenuList(List<MenuItemModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.coffee_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Chưa có món nào trong danh mục này',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildMenuCard(items[i]),
    );
  }

  Widget _buildMenuCard(MenuItemModel item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ✅ Đã sửa: Sử dụng imageURL (viết hoa)
            _buildItemThumbnail(item.imageURL),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C1A0E)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildTag(item.category, const Color(0xFF6F4E37)),
                      const SizedBox(width: 8),
                      _buildTag(
                        item.isAvailable ? 'Có sẵn' : 'Tạm hết',
                        item.isAvailable ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatPrice(item.price)}đ',
                    style: const TextStyle(
                      color: Color(0xFF6F4E37),
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _ActionIconButton(
                  icon: Icons.edit_note_rounded,
                  color: const Color(0xFF1565C0),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.managerMenuEdit,
                    arguments: item,
                  ),
                ),
                const SizedBox(height: 12),
                _ActionIconButton(
                  icon: Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                  onTap: () => _confirmDelete(context, item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemThumbnail(String url) {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: const Color(0xFFF5EDE0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6F4E37).withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: _getImageWidget(url),
      ),
    );
  }

  Widget _getImageWidget(String url) {
    if (url.isEmpty) return const Center(child: Text('☕', style: TextStyle(fontSize: 32)));

    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6F4E37)));
        },
        errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    }

    final file = File(url);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }

    return const Center(child: Text('☕', style: TextStyle(fontSize: 32)));
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MenuItemModel item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa món "${item.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final menuProvider = Provider.of<MenuProvider>(context, listen: false);
              await menuProvider.deleteMenuItem(item.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã xóa "${item.name}"')),
                );
              }
            },
            child: const Text('Xóa ngay', style: TextStyle(color: Colors.white)),
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
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
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
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: color),
    ),
  );
}