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
  // Theme colors consistent with HTML template
  static const _bgWarm = Color(0xFFFDF8F6);
  static const _coffee50 = Color(0xFFFDF8F6);
  static const _coffee100 = Color(0xFFF2E8E5);
  static const _coffee200 = Color(0xFFEADDD7);
  static const _coffee600 = Color(0xFF8C634F);
  static const _coffee900 = Color(0xFF4A332D);
  static const _emerald600 = Color(0xFF059669);

  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    // ✅ Lắng nghe dữ liệu thời gian thực từ Firestore
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
          backgroundColor: _bgWarm,
          floatingActionButton: FloatingActionButton(
            backgroundColor: _coffee600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.managerMenuAdd),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(menuProvider),
                _buildCategoryFilter(categories),
                _buildSummaryBar(filteredItems),
                if (menuProvider.isLoading && filteredItems.isEmpty)
                  const Expanded(child: Center(child: CircularProgressIndicator(color: _coffee600)))
                else
                  Expanded(child: _buildMenuList(filteredItems)),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeader(MenuProvider menuProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _coffee100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                // Do yêu cầu "bỏ nút back" nhưng vì Manager navigation có thể push tới MenuListScreen thay cho ManagerDashboard
                // Nên an toàn nhất là ta không dùng AppBar mặc định và tự điều khiển leading:
                // Nếu Navigator có thể pop thì hiện back, không thì không hiện. 
                icon: const Icon(Icons.arrow_back_rounded, color: _coffee900),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('QUẢN LÝ QUÁN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _coffee600, letterSpacing: 0.5)),
                  const Text('Thực đơn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _coffee900)),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _coffee600),
            onPressed: () => menuProvider.fetchMenuItems(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    final allCategories = ['Tất cả', ...categories];
    return Container(
      color: Colors.white,
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = allCategories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: selected ? _coffee600 : _coffee50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? _coffee600 : _coffee200),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : _coffee900,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
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
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _coffee50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _coffee100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SummaryChip(label: 'Tổng số món', value: '$total', color: _coffee900),
          _SummaryChip(label: 'Có sẵn', value: '$available', color: _emerald600),
          _SummaryChip(label: 'Tạm hết', value: '${total - available}', color: const Color(0xFFD97706)),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: _coffee100, shape: BoxShape.circle),
              child: const Icon(Icons.coffee_outlined, size: 48, color: _coffee600),
            ),
            const SizedBox(height: 16),
            const Text('Chưa có món nào', style: TextStyle(color: _coffee600, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildMenuCard(items[i]),
    );
  }

  Widget _buildMenuCard(MenuItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _coffee100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            _buildItemThumbnail(item.imageUrl),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _coffee900)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildTag(item.category, _coffee600, _coffee50),
                      const SizedBox(width: 8),
                      _buildTag(
                        item.isAvailable ? 'Có sẵn' : 'Tạm hết',
                        item.isAvailable ? _emerald600 : const Color(0xFFD97706),
                        item.isAvailable ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('${_formatPrice(item.price)}đ', style: const TextStyle(color: _coffee900, fontWeight: FontWeight.w900, fontSize: 15)),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                _ActionIconButton(
                  icon: Icons.edit_rounded,
                  color: _coffee600,
                  bgColor: _coffee50,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.managerMenuEdit, arguments: item),
                ),
                const SizedBox(height: 10),
                _ActionIconButton(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red[600]!,
                  bgColor: Colors.red[50]!,
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
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _coffee50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _getImageWidget(url),
      ),
    );
  }

  Widget _getImageWidget(String url) {
    if (url.isEmpty) return const Center(child: Icon(Icons.local_cafe_rounded, color: _coffee200, size: 32));

    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: _coffee200)));
        },
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.local_cafe_rounded, color: _coffee200, size: 32)),
      );
    }
    return const Center(child: Icon(Icons.local_cafe_rounded, color: _coffee200, size: 32));
  }

  Widget _buildTag(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MenuItemModel item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xác nhận xóa', style: TextStyle(color: _coffee900, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa món "${item.name}" không? Thao tác này không thể hoàn tác.', style: const TextStyle(color: _coffee600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final menuProvider = Provider.of<MenuProvider>(context, listen: false);
              await menuProvider.deleteMenuItem(item.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa "${item.name}"'),
                    backgroundColor: Colors.red[600]!,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Xóa ngay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// --- SUPPORTING WIDGETS ---

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
    ],
  );
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  const _ActionIconButton({required this.icon, required this.color, required this.bgColor, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color),
    ),
  );
}