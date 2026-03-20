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
    try {
      await _firestore.collection('ingredients').add(ingredient.toMap());
    } catch (e) {
      print('❌ Lỗi thêm nguyên liệu: $e');
    }
  }

  // Cập nhật nguyên liệu (Sửa số lượng thủ công)
  Future<void> updateIngredient(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('ingredients').doc(id).update(data);
    } catch (e) {
      print('❌ Lỗi cập nhật: $e');
    }
  }

  @override
  void dispose() {
    _ingredientSub?.cancel(); // ✅ Hủy lắng nghe khi không dùng nữa
    super.dispose();
  }
}