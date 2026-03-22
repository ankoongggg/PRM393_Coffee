import 'dart:async'; // ✅ Thêm import này
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ingredient_model.dart';

class IngredientProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<IngredientModel> _ingredients = [];
  bool _isLoading = false;
  StreamSubscription? _ingredientSub;

  List<IngredientModel> get ingredients => _ingredients;
  bool get isLoading => _isLoading;

  /// Kiểm tra tên nguyên liệu đã tồn tại chưa (khi sửa: loại trừ id)
  bool hasDuplicateName(String name, {String? excludeId}) {
    final lower = name.trim().toLowerCase();
    return _ingredients.any((i) =>
        i.name.trim().toLowerCase() == lower && (excludeId == null || i.id != excludeId));
  }

  /// Xóa nguyên liệu
  Future<void> deleteIngredient(String id) async {
    try {
      await _firestore.collection('ingredients').doc(id).delete();
    } catch (e) {
      print('❌ Lỗi xóa nguyên liệu: $e');
      rethrow;
    }
  }

  // ✅ Tự động khởi động listener khi Provider được tạo (giống MenuProvider, OrderProvider)
  IngredientProvider() {
    startIngredientListener();
  }

  // ✅ Lắng nghe dữ liệu realtime
  void startIngredientListener() {
    if (_ingredientSub != null) return; // Tránh lắng nghe trùng lặp

    _isLoading = true;
    notifyListeners();

    _ingredientSub = _firestore
        .collection('ingredients')
        .orderBy('name')
        .snapshots()
        .listen((snapshot) {
      _ingredients = snapshot.docs
          .map((doc) => IngredientModel.fromMap(doc.id, doc.data()))
          .toList();
      _isLoading = false;
      notifyListeners(); // 🚀 Ép UI (InventoryScreen và Menu) vẽ lại
      print('📦 Kho đã cập nhật dữ liệu mới từ Firebase');
    });
  }

  // Thêm nguyên liệu mới
  Future<void> addIngredient(IngredientModel ingredient) async {
    if (hasDuplicateName(ingredient.name)) {
      throw Exception('Tên nguyên liệu "${ingredient.name}" đã tồn tại');
    }
    try {
      await _firestore.collection('ingredients').add(ingredient.toMap());
    } catch (e) {
      print('❌ Lỗi thêm nguyên liệu: $e');
      rethrow;
    }
  }

  // Cập nhật nguyên liệu (Sửa số lượng thủ công)
  Future<void> updateIngredient(String id, Map<String, dynamic> data) async {
    final name = data['name']?.toString().trim();
    if (name != null && hasDuplicateName(name, excludeId: id)) {
      throw Exception('Tên nguyên liệu "$name" đã tồn tại');
    }
    try {
      await _firestore.collection('ingredients').doc(id).update(data);
    } catch (e) {
      print('❌ Lỗi cập nhật: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _ingredientSub?.cancel(); // ✅ Hủy lắng nghe khi không dùng nữa
    super.dispose();
  }
}