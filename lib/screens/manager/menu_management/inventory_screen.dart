import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/ingredient_provider.dart';
import '../../../models/ingredient_model.dart';
import '../../../routes/app_routes.dart';
import '../manager_navigation_bar.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _selectedNavIndex = 3; // STOCK tab

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IngredientProvider>(context, listen: false).startIngredientListener();
    });
  }

  // Popup Thêm hoặc Sửa nguyên liệu
  void _showAddEditDialog([IngredientModel? ingredient]) {
    final isEdit = ingredient != null;
    final nameCtrl = TextEditingController(text: ingredient?.name ?? '');
    final unitCtrl = TextEditingController(text: ingredient?.unit ?? '');
    final stockCtrl = TextEditingController(text: ingredient?.stock.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Sửa nguyên liệu' : 'Thêm nguyên liệu mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên (VD: Cam tươi)')),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Đơn vị (VD: quả, gram)')),
              TextField(
                controller: stockCtrl,
                decoration: const InputDecoration(labelText: 'Số lượng tồn kho'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final unit = unitCtrl.text.trim();
              final stock = double.tryParse(stockCtrl.text) ?? 0;
              if (name.isEmpty || unit.isEmpty) return;

              final newIng = IngredientModel(
                id: ingredient?.id ?? '',
                name: name,
                unit: unit,
                stock: stock,
              );

              final provider = Provider.of<IngredientProvider>(context, listen: false);
              try {
                if (isEdit) {
                  await provider.updateIngredient(newIng.id, newIng.toMap());
                } else {
                  await provider.addIngredient(newIng);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteIngredient(BuildContext context, IngredientModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa "${item.name}"?'),
        content: const Text('Bạn có chắc muốn xóa nguyên liệu này khỏi kho?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await Provider.of<IngredientProvider>(context, listen: false).deleteIngredient(item.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa nguyên liệu'), backgroundColor: Color(0xFF6F4E37)),
                  );
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F5),
        elevation: 0,
        automaticallyImplyLeading: false,
        shape: const Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
        title: const Text('Quản Lý Kho Nguyên Liệu', style: TextStyle(color: Color(0xFF361F1A), fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF361F1A)),
            onPressed: () => Provider.of<IngredientProvider>(context, listen: false).startIngredientListener(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF361F1A)),
            tooltip: 'Đăng xuất',
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF361F1A),
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nhập Kho', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditDialog(),
      ),
      backgroundColor: const Color(0xFFFBF9F5),
      body: Consumer<IngredientProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.ingredients.isEmpty) return const Center(child: Text('Kho đang trống!'));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: provider.ingredients.length,
            itemBuilder: (ctx, i) {
              final item = provider.ingredients[i];
              // Báo đỏ nếu tồn kho bằng 0
              final isOutOfStock = item.stock <= 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showAddEditDialog(item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: isOutOfStock ? Colors.red.withValues(alpha: 0.1) : const Color(0xFF003A76).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded, 
                              color: isOutOfStock ? Colors.red : const Color(0xFF003A76),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name, 
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF361F1A)),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      isOutOfStock ? Icons.error_outline : Icons.check_circle_outline, 
                                      size: 16, 
                                      color: isOutOfStock ? Colors.red : const Color(0xFF27AE60),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isOutOfStock ? 'Hết hàng' : 'Tồn kho: ${item.stock} ${item.unit}',
                                      style: TextStyle(
                                        color: isOutOfStock ? Colors.red : const Color(0xFF504442),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _confirmDeleteIngredient(ctx, item),
                            icon: const Icon(Icons.delete_outline, size: 22, color: Colors.red),
                            tooltip: 'Xóa nguyên liệu',
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF9F5),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE4E2DE)),
                            ),
                            child: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF9E7B5A)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: buildManagerBottomNavigation(
        context: context,
        selectedIndex: _selectedNavIndex,
        onIndexChanged: (index) => setState(() => _selectedNavIndex = index),
      ),
    );
  }
}