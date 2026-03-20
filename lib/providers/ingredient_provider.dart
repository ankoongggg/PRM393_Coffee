import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ingredient_model.dart';

class IngredientProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<IngredientModel> _ingredients = [];
  bool isLoading = false;

  List<IngredientModel> get ingredients => _ingredients;

  // Lắng nghe dữ liệu realtime từ Firebase
  void startIngredientListener() {
    isLoading = true;
    notifyListeners();

    _firestore.collection('ingredients').orderBy('name').snapshots().listen((snapshot) {
      _ingredients = snapshot.docs
          .map((doc) => IngredientModel.fromMap(doc.id, doc.data()))
          .toList();
      isLoading = false;
      notifyListeners();
    });
  }

  // Thêm nguyên liệu mới
  Future<void> addIngredient(IngredientModel ingredient) async {
    await _firestore.collection('ingredients').add(ingredient.toMap());
  }

  // Cập nhật nguyên liệu
  Future<void> updateIngredient(String id, Map<String, dynamic> data) async {
    await _firestore.collection('ingredients').doc(id).update(data);
  }

  // Xóa nguyên liệu
  Future<void> deleteIngredient(String id) async {
    await _firestore.collection('ingredients').doc(id).delete();
  }
}