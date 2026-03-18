import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/menu_provider.dart';
import '../../../services/firebase_service.dart';

class AddEditMenuItemScreen extends StatefulWidget {
  final MenuItemModel? menuItem;
  const AddEditMenuItemScreen({super.key, this.menuItem});

  @override
  State<AddEditMenuItemScreen> createState() => _AddEditMenuItemScreenState();
}

class _AddEditMenuItemScreenState extends State<AddEditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _imageCtrl = TextEditingController(); // giữ để hiển thị URL hiện tại (read-only)
  String _selectedCategory = 'Espresso';
  bool _isAvailable = true;
  XFile? _pickedXFile;
  Uint8List? _pickedBytes;
  bool _isUploading = false;

  bool get _isEdit => widget.menuItem != null;
  final List<String> _categories = [
    'Espresso',
    'Latte',
    'Cappuccino',
    'Cold Brew',
    'Frappe',
    'Matcha',
    'Trà trái cây',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.menuItem!.name;
      _descCtrl.text = widget.menuItem!.description;
      _priceCtrl.text = widget.menuItem!.price.toStringAsFixed(0);
      _imageCtrl.text = widget.menuItem!.imageUrl;

      // ✅ LOGIC AN TOÀN: Kiểm tra xem category có tồn tại trong list không
      final String dbCategory = widget.menuItem!.category;
      if (_categories.contains(dbCategory)) {
        _selectedCategory = dbCategory;
      } else {
        // Nếu không khớp (ví dụ Database là "Trà sữa" mà code chưa có),
        // chọn cái đầu tiên để tránh Crash màn hình đỏ.
        _selectedCategory = _categories.first;
      }

      _isAvailable = widget.menuItem!.isAvailable;
    }
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
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _pickedXFile = pickedFile;
        _pickedBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F5),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF361F1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Chỉnh sửa món' : 'Thêm món mới',
          style: const TextStyle(color: Color(0xFF361F1A), fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _submit,
            icon: const Icon(Icons.check, color: Color(0xFF361F1A)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(20),
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 20),
              _buildSection('Thông tin cơ bản', [
                _buildTextField(_nameCtrl, 'Tên món', Icons.coffee, required: true),
                const SizedBox(height: 14),
                _buildTextField(_descCtrl, 'Mô tả', Icons.description_outlined, maxLines: 3),
              ]),
              const SizedBox(height: 16),
              _buildSection('Giá & Danh mục', [
                _buildTextField(
                  _priceCtrl, 'Giá (VNĐ)', Icons.attach_money,
                  required: true,
                  keyboardType: TextInputType.number,
                  suffix: 'đ',
                ),
                const SizedBox(height: 14),
                _buildCategoryDropdown(),
              ]),
              const SizedBox(height: 16),
              _buildSection('Ảnh', [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _imageCtrl.text.isEmpty ? 'Chưa có ảnh' : 'Đang dùng ảnh đã lưu',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9E7B5A)),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Chọn ảnh'),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 16),
              _buildAvailableToggle(),
              const SizedBox(height: 28),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E2DE), width: 1.5),
      ),
      child: _pickedBytes != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(_pickedBytes!, fit: BoxFit.cover),
            )
          : _imageCtrl.text.startsWith('http')
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    _imageCtrl.text,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: Color(0xFF9C7B5A)),
                  ),
                )
              : const Icon(Icons.add_a_photo, size: 40, color: Color(0xFF9C7B5A)),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF361F1A))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.transparent),
            boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl,
      String hint,
      IconData icon, {
        bool required = false,
        int maxLines = 1,
        TextInputType? keyboardType,
        String? suffix,
      }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Không được để trống' : null : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF504442), size: 20),
        suffixText: suffix,
        filled: true,
        fillColor: const Color(0xFFFDFBF7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2DE))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2DE))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF361F1A), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF504442), size: 20),
        hintText: 'Chọn danh mục',
        filled: true,
        fillColor: const Color(0xFFFDFBF7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2DE))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2DE))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF361F1A), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => _selectedCategory = v!),
    );
  }

  Widget _buildAvailableToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF361F1A)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trạng thái có sẵn', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF361F1A))),
                Text('Món sẽ hiển thị khi Waiter tạo order', style: TextStyle(fontSize: 11, color: Color(0xFF504442), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Switch(
            value: _isAvailable,
            activeTrackColor: const Color(0xFF361F1A).withOpacity(0.4),
            activeThumbColor: const Color(0xFF361F1A),
            onChanged: (v) => setState(() => _isAvailable = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : _submit,
        icon: Icon(_isEdit ? Icons.save : Icons.add, color: Colors.white),
        label: Text(
          _isUploading ? 'Đang tải ảnh...' : (_isEdit ? 'Lưu thay đổi' : 'Thêm món mới'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF361F1A),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);
      final firebaseService = FirebaseService();

      String imageUrl = _imageCtrl.text;
      try {
        if (_pickedXFile != null) {
          setState(() => _isUploading = true);
          final ext = (_pickedXFile!.name.split('.').last).toLowerCase();
          imageUrl = await firebaseService.uploadMenuItemImageBytes(
            bytes: _pickedBytes!,
            fileExt: ext,
          );
          _imageCtrl.text = imageUrl;
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }

      final item = MenuItemModel(
        id: _isEdit ? widget.menuItem!.id : '',
        name: _nameCtrl.text,
        description: _descCtrl.text,
        price: double.tryParse(_priceCtrl.text) ?? 0,
        imageUrl: imageUrl,
        category: _selectedCategory,
        isAvailable: _isAvailable,
      );

      try {
        if (_isEdit) {
          await menuProvider.updateMenuItem(item);
        } else {
          await menuProvider.addMenuItem(item);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEdit ? 'Đã cập nhật món!' : 'Đã thêm món mới!'),
              backgroundColor: const Color(0xFF6F4E37),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}