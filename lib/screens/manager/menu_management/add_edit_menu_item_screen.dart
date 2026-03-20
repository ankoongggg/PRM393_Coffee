import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../models/menu_item_model.dart';
import '../../../models/ingredient_model.dart';
import '../../../providers/menu_provider.dart';
import '../../../providers/ingredient_provider.dart';

class AddEditMenuItemScreen extends StatefulWidget {
  final MenuItemModel? menuItem;
  const AddEditMenuItemScreen({super.key, this.menuItem});

  @override
  State<AddEditMenuItemScreen> createState() => _AddEditMenuItemScreenState();
}

class _AddEditMenuItemScreenState extends State<AddEditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _imageCtrl;

  String _selectedCategory = 'Espresso';
  bool _isAvailable = true;
  File? _imageFile;

  // ✅ Ép kiểu rõ ràng Map<String, dynamic> để khớp với Firebase/Model
  Map<String, dynamic> _currentRecipe = {};

  bool get _isEdit => widget.menuItem != null;

  final List<String> _categories = [
    'Espresso', 'Latte', 'Cappuccino', 'Cold Brew', 'Frappe', 'Matcha', 'Trà trái cây',
  ];

  @override
  void initState() {
    super.initState();

    // Khởi tạo controllers
    _nameCtrl = TextEditingController(text: widget.menuItem?.name ?? '');
    _descCtrl = TextEditingController(text: widget.menuItem?.description ?? '');
    _priceCtrl = TextEditingController(
        text: widget.menuItem != null ? widget.menuItem!.price.toStringAsFixed(0) : ''
    );
    // ✅ Sử dụng imageURL (Viết hoa theo Model mới)
    _imageCtrl = TextEditingController(text: widget.menuItem?.imageURL ?? '');

    _isAvailable = widget.menuItem?.isAvailable ?? true;

    // ✅ Ép kiểu Map an toàn từ MenuItem sang biến tạm
    if (widget.menuItem?.recipe != null) {
      _currentRecipe = Map<String, dynamic>.from(widget.menuItem!.recipe!);
    }

    if (_isEdit && _categories.contains(widget.menuItem!.category)) {
      _selectedCategory = widget.menuItem!.category;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IngredientProvider>(context, listen: false).startIngredientListener();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageCtrl.text = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F1),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6F4E37),
        title: Text(_isEdit ? 'Chỉnh sửa món' : 'Thêm món mới',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildImagePreview()),
              const SizedBox(height: 24),
              _buildSection('Thông tin cơ bản', [
                _buildTextField(_nameCtrl, 'Tên món', Icons.coffee, isReq: true),
                const SizedBox(height: 14),
                _buildTextField(_descCtrl, 'Mô tả', Icons.description_outlined, maxLines: 3),
              ]),
              const SizedBox(height: 16),
              _buildSection('Giá & Danh mục', [
                _buildTextField(_priceCtrl, 'Giá (VNĐ)', Icons.attach_money,
                    isReq: true, keyboardType: TextInputType.number, suffix: 'đ'),
                const SizedBox(height: 14),
                _buildCategoryDropdown(),
              ]),
              const SizedBox(height: 16),
              _buildSection('Ảnh', [
                _buildTextField(_imageCtrl, 'URL ảnh', Icons.link),
              ]),
              const SizedBox(height: 16),
              _buildSection('Công thức định lượng', [
                _buildRecipeSection(),
              ]),
              const SizedBox(height: 16),
              _buildAvailableToggle(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeSection() {
    return Consumer<IngredientProvider>(
      builder: (context, provider, _) {
        final allIng = provider.ingredients;

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            if (_currentRecipe.isNotEmpty)
              ..._currentRecipe.entries.map((entry) {
                final String ingId = entry.key;
                final double qty = (entry.value as num).toDouble();

                IngredientModel? ing;
                try {
                  ing = allIng.firstWhere((i) => i.id == ingId);
                } catch (_) {
                  ing = null;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF6F1),
                    borderRadius: BorderRadius.circular(10),
                    // ✅ Dùng withValues thay cho withOpacity
                    border: Border.all(color: Colors.brown.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF6F4E37)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ing != null ? ing.name : 'ID: $ingId',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('$qty ${ing?.unit ?? ""}',
                          style: const TextStyle(color: Color(0xFF6F4E37), fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => setState(() => _currentRecipe.remove(ingId)),
                      ),
                    ],
                  ),
                );
              })
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Chưa có định lượng.', style: TextStyle(color: Colors.grey)),
              ),
            OutlinedButton.icon(
              onPressed: () => _showAddIngredientDialog(allIng),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Thêm thành phần'),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6F4E37)),
            ),
          ],
        );
      },
    );
  }

  void _showAddIngredientDialog(List<IngredientModel> ingredients) {
    String? localSelectedId;
    final qtyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm nguyên liệu'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                hint: const Text('Chọn nguyên liệu'),
                value: localSelectedId,
                items: ingredients.map((ing) => DropdownMenuItem(
                  value: ing.id,
                  child: Text('${ing.name} (${ing.unit})'),
                )).toList(),
                onChanged: (val) => setDialogState(() => localSelectedId = val),
              ),
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Số lượng cần dùng'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              final qty = double.tryParse(qtyCtrl.text);
              if (localSelectedId != null && qty != null && qty > 0) {
                setState(() => _currentRecipe[localSelectedId!] = (_currentRecipe[localSelectedId!] ?? 0) + qty);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: 140, height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFF5EDE0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF6F4E37), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: _imageFile != null
              ? Image.file(_imageFile!, fit: BoxFit.cover)
              : _imageCtrl.text.isNotEmpty
              ? Image.network(_imageCtrl.text, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
              : const Icon(Icons.add_a_photo, size: 40, color: Color(0xFF9C7B5A)),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6F4E37))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {bool isReq = false, int maxLines = 1, TextInputType? keyboardType, String? suffix}) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines, keyboardType: keyboardType,
      validator: isReq ? (v) => (v == null || v.isEmpty) ? 'Bắt buộc' : null : null,
      decoration: InputDecoration(
        hintText: hint, prefixIcon: Icon(icon, size: 20), suffixText: suffix,
        filled: true, fillColor: const Color(0xFFFAF6F1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => _selectedCategory = v!),
      decoration: const InputDecoration(filled: true, fillColor: Color(0xFFFAF6F1), border: InputBorder.none),
    );
  }

  Widget _buildAvailableToggle() {
    return SwitchListTile(
      title: const Text('Trạng thái có sẵn', style: TextStyle(fontWeight: FontWeight.bold)),
      value: _isAvailable,
      onChanged: (v) => setState(() => _isAvailable = v),
      activeColor: const Color(0xFF6F4E37),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6F4E37),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(_isEdit ? 'CẬP NHẬT MÓN' : 'THÊM VÀO THỰC ĐƠN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);

      // ✅ Tạo Model mới khớp chính xác với fields đã thống nhất
      final item = MenuItemModel(
        id: _isEdit ? widget.menuItem!.id : '',
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        description: _descCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text) ?? 0,
        imageURL: _imageCtrl.text.trim(), // ✅ imageURL hoa
        isAvailable: _isAvailable,
        recipe: _currentRecipe,
        quantity: widget.menuItem?.quantity ?? 0,
      );

      try {
        if (_isEdit) {
          await menuProvider.updateMenuItem(item);
        } else {
          await menuProvider.addMenuItem(item);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }
}