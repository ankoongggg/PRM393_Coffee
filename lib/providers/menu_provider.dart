import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/menu_item_model.dart';
import '../models/ingredient_model.dart';
import '../services/firebase_service.dart';

class MenuProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<MenuItemModel> _rawMenuItems = [];    // Dữ liệu gốc từ Firebase
  List<MenuItemModel> _displayMenuItems = []; // Dữ liệu đã tính toán Quantity
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _menuSubscription;

  // Getters
  List<MenuItemModel> get menuItems => _displayMenuItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MenuProvider() {
    startMenuListener();
  }

  // ─────────────────────────────────────────────────────────────
  // 🧠 LOGIC TÍNH TOÁN QUANTITY (TRÁI TIM CỦA HỆ THỐNG)
  // ─────────────────────────────────────────────────────────────

  /// ✅ Hàm tính số lượng ly tối đa dựa trên kho nguyên liệu (Bottleneck Logic)
  void updateAvailableQuantities(List<IngredientModel> ingredients) {
    if (ingredients.isEmpty) return;

    // Duyệt qua danh sách gốc và tính toán quantity động dựa trên công thức (recipe)
    _displayMenuItems = _rawMenuItems.map((item) {
      // Nếu món không có công thức (recipe), coi như không có giới hạn hoặc mặc định 0
      if (item.recipe == null || item.recipe!.isEmpty) {
        return item.copyWith(quantity: 0);
      }

      List<int> possibleCounts = [];

      item.recipe!.forEach((ingId, dosage) {
        // Tìm nguyên liệu trong kho dựa trên ID trong công thức
        final stockIng = ingredients.firstWhere(
              (ing) => ing.id == ingId,
          orElse: () => IngredientModel(
            id: 'unknown',
            name: 'Unknown',
            stock: 0,
            unit: '',
          ),
        );

        if (dosage > 0) {
          // Công thức: Số ly = Tồn kho / Định mức 1 ly
          int canMake = (stockIng.stock / dosage).floor();
          if (canMake < 0) canMake = 0; // ✅ Không cho âm
          possibleCounts.add(canMake);
        }
      });

      int finalQty = possibleCounts.isEmpty ? 0 : possibleCounts.reduce((a, b) => a < b ? a : b);
      if (finalQty < 0) finalQty = 0; // ✅ Đảm bảo không bao giờ hiện số âm

      return item.copyWith(quantity: finalQty);
    }).toList();

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // SYNC & FETCH (Đồng bộ dữ liệu)
  // ─────────────────────────────────────────────────────────────

  /// Lắng nghe thay đổi thời gian thực từ Firestore
  void startMenuListener() {
    _menuSubscription?.cancel();
    _setLoading(true);

    _menuSubscription = _firebaseService.getMenuItemsStream().listen(
          (newList) {
        _rawMenuItems = newList;
        _displayMenuItems = newList; // Khởi tạo tạm thời trước khi tính toán
        _error = null;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _error = 'Lỗi stream menu: $e';
        _setLoading(false);
        notifyListeners();
      },
    );
  }

  /// ✅ Hàm fetch thủ công (Fix lỗi cho màn hình MenuListScreen)
  Future<void> fetchMenuItems() async {
    _setLoading(true);
    try {
      _rawMenuItems = await _firebaseService.fetchAllMenuItems();
      _displayMenuItems = _rawMenuItems;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Lỗi fetch menu: $e';
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CRUD (Thêm, Sửa, Xóa cho Manager)
  // ─────────────────────────────────────────────────────────────

  Future<void> addMenuItem(MenuItemModel item) async {
    try {
      await _firebaseService.addMenuItem(item.toMap());
    } catch (e) {
      _error = 'Lỗi thêm món: $e';
      rethrow;
    }
  }

  Future<void> updateMenuItem(MenuItemModel item) async {
    try {
      await _firebaseService.updateMenuItem(item.id, item.toMap());
    } catch (e) {
      _error = 'Lỗi cập nhật: $e';
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String id) async {
    try {
      await _firebaseService.deleteMenuItem(id);
    } catch (e) {
      _error = 'Lỗi xóa món: $e';
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FILTER & HELPERS
  // ─────────────────────────────────────────────────────────────

  List<MenuItemModel> filterByCategory(String category) {
    if (category == 'Tất cả') {
      return _displayMenuItems; // Trả về danh sách đã tính toán Quantity
    }
    return _displayMenuItems
        .where((item) => item.category == category)
        .toList();
  }

  List<String> getCategories() {
    final categories = <String>{'Tất cả'};
    for (var item in _rawMenuItems) {
      categories.add(item.category);
    }
    return categories.toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _menuSubscription?.cancel();
    super.dispose();
  }
}