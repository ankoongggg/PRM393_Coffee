// TODO: Implement AuthProvider
// Chịu trách nhiệm: đăng nhập, đăng xuất, lưu session user

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // TODO: login(email, password) - xác thực user, lấy role
  // TODO: logout() - xóa session
  // TODO: loadSession() - khôi phục session từ SharedPreferences
}
