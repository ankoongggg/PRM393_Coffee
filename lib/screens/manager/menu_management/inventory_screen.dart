import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/ingredient_provider.dart';
import '../../../models/ingredient_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
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
            onPressed: () {
              final newIng = IngredientModel(
                id: ingredient?.id ?? '',
                name: nameCtrl.text.trim(),
                unit: unitCtrl.text.trim(),
                stock: double.tryParse(stockCtrl.text) ?? 0,
              );

              final provider = Provider.of<IngredientProvider>(context, listen: false);
              if (isEdit) {
                provider.updateIngredient(newIng.id, newIng.toMap());
              } else {
                provider.addIngredient(newIng);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho Nguyên Liệu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6F4E37),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6F4E37),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nhập Kho', style: TextStyle(color: Colors.white)),
        onPressed: () => _showAddEditDialog(),
      ),
      body: Consumer<IngredientProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.ingredients.isEmpty) return const Center(child: Text('Kho đang trống!'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.ingredients.length,
            itemBuilder: (ctx, i) {
              final item = provider.ingredients[i];
              // Báo đỏ nếu tồn kho bằng 0
              final isOutOfStock = item.stock <= 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isOutOfStock ? Colors.red[100] : Colors.blue[100],
                    child: Icon(Icons.kitchen, color: isOutOfStock ? Colors.red : Colors.blue[800]),
                  ),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(
                    isOutOfStock ? 'HẾT HÀNG' : 'Tồn kho: ${item.stock} ${item.unit}',
                    style: TextStyle(
                      color: isOutOfStock ? Colors.red : Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () => _showAddEditDialog(item),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}