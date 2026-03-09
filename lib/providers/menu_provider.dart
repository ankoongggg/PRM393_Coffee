// TODO: Implement MenuProvider
// Chịu trách nhiệm: CRUD menu items (Manager)

import 'package:flutter/foundation.dart';
import '../models/menu_item_model.dart';

class MenuProvider extends ChangeNotifier {
  List<MenuItemModel> _menuItems = [];

  List<MenuItemModel> get menuItems => List.unmodifiable(_menuItems);

  // TODO: fetchMenuItems() - lấy danh sách menu
  // TODO: addMenuItem(MenuItemModel item) - thêm món mới
  // TODO: updateMenuItem(MenuItemModel item) - sửa món
  // TODO: deleteMenuItem(String id) - xóa món
  // TODO: toggleAvailability(String id) - bật/tắt trạng thái có sẵn
}
