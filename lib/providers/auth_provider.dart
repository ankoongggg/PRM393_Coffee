import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../core/enums/user_role.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  // Hàm đăng nhập (Đang dùng dữ liệu giả lập để test UI trước)
  Future<bool> login(String email, String password, UserRole selectedRole) async {
    _errorMessage = null;
    notifyListeners();

    try {
      // Giả lập thời gian chờ load mạng 1.5 giây
      await Future.delayed(const Duration(milliseconds: 1500));

      // Validate cơ bản
      if (password.length < 6) {
        _errorMessage = 'Mật khẩu phải từ 6 ký tự trở lên';
        notifyListeners();
        return false;
      }

      // Mock dữ liệu đăng nhập thành công
      _currentUser = UserModel(
        id: 'user_123',
        name: 'Nguyễn Văn A',
        email: email,
        role: selectedRole, // Đã sửa lỗi ở đây (bỏ .name)
      );

      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}