// TODO: Implement MenuProvider
// Chịu trách nhiệm: CRUD menu items (Manager)

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/menu_item_model.dart';
import '../services/firebase_service.dart';

class MenuProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<MenuItemModel> _menuItems = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _menuSubscription;

  List<MenuItemModel> get menuItems => List.unmodifiable(_menuItems);
  bool get isLoading => _isLoading;
  String? get error => _error;

  MenuProvider() {
    startMenuListener();
  }

  void startMenuListener() {
    _menuSubscription?.cancel();
    _setLoading(true);

    _menuSubscription = _firebaseService.getMenuItemsStream().listen(
          (newList) {
        _menuItems = newList;
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

  // ─────────────────────────────────────────────────────────────
  // FETCH MENU ITEMS
  // ─────────────────────────────────────────────────────────────

  /// Lấy tất cả menu items
  Future<void> fetchMenuItems() async {
    _setLoading(true);
    try {
      _menuItems = await _firebaseService.fetchAllMenuItems();
      _error = null;
      print('✅ Fetch ${_menuItems.length} menu items thành công');
    } catch (e) {
      _error = 'Lỗi fetch menu items: $e';
      print('❌ $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy menu items có sẵn (for ordering)
  Future<void> fetchAvailableMenuItems() async {
    _setLoading(true);
    try {
      _menuItems = await _firebaseService.fetchAvailableMenuItems();
      _error = null;
      print('✅ Fetch ${_menuItems.length} available menu items');
    } catch (e) {
      _error = 'Lỗi fetch menu items: $e';
      print('❌ $_error');
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FILTER
  // ─────────────────────────────────────────────────────────────

  /// Lấy categories từ menu items
  List<String> getCategories() {
    final categories = <String>{'Tất cả'};
    for (var item in _menuItems) {
      categories.add(item.category);
    }
    return categories.toList();
  }

  /// Lọc menu items theo category
  List<MenuItemModel> filterByCategory(String category) {
    if (category == 'Tất cả') {
      return _menuItems;
    }
    return _menuItems.where((item) => item.category == category).toList();
  }

  /// Tìm kiếm menu items
  List<MenuItemModel> searchMenuItems(String query) {
    return _menuItems
        .where((item) =>
    item.name.toLowerCase().contains(query.toLowerCase()) ||
        item.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────
  // CRUD (Manager)
  // ─────────────────────────────────────────────────────────────

  /// Thêm menu item mới (Manager)
  Future<void> addMenuItem(MenuItemModel item) async {
    try {
      // Bạn cần đảm bảo đã thêm hàm addMenuItem vào FirebaseService
      await _firebaseService.addMenuItem(item.toMap());
      print('✅ Thêm món ${item.name} thành công');
    } catch (e) {
      _error = 'Lỗi thêm menu item: $e';
      print('❌ $_error');
      rethrow;
    }
  }

  /// Sửa menu item (Manager)
  Future<void> updateMenuItem(MenuItemModel item) async {
    try {
      // Bạn cần đảm bảo đã thêm hàm updateMenuItem vào FirebaseService
      await _firebaseService.updateMenuItem(item.id, item.toMap());
      print('✅ Cập nhật món ${item.name} thành công');
    } catch (e) {
      _error = 'Lỗi sửa menu item: $e';
      print('❌ $_error');
      rethrow;
    }
  }

  /// Xóa menu item (Manager)
  Future<void> deleteMenuItem(String id) async {
    try {
      // Bạn cần đảm bảo đã thêm hàm deleteMenuItem vào FirebaseService
      await _firebaseService.deleteMenuItem(id);
      print('✅ Xóa món thành công');
    } catch (e) {
      _error = 'Lỗi xóa menu item: $e';
      print('❌ $_error');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

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