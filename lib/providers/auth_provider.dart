import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../core/enums/user_role.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  // Danh sách tài khoản mặc định để validation
  final Map<UserRole, Map<String, String>> _defaultAccounts = {
    UserRole.manager: {'email': 'manager@gmail.com', 'password': 'Password123'},
    UserRole.waiter: {'email': 'waiter@gmail.com', 'password': 'Password123'},
    UserRole.barista: {'email': 'barista@gmail.com', 'password': 'Password123'},
  };

  // Hàm đăng nhập (Đang dùng dữ liệu giả lập để test UI trước)
  Future<bool> login(String email, String password, UserRole selectedRole) async {
    _errorMessage = null;
    notifyListeners();

    try {
      // Giả lập thời gian chờ load mạng 1.5 giây
      await Future.delayed(const Duration(milliseconds: 1500));

      // Validate dữ liệu nhập
      if (email.isEmpty || password.isEmpty) {
        _errorMessage = 'Vui lòng nhập đầy đủ email và mật khẩu';
        notifyListeners();
        return false;
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _errorMessage = 'Email không đúng định dạng';
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _errorMessage = 'Mật khẩu phải từ 6 ký tự trở lên';
        notifyListeners();
        return false;
      }

      if (!RegExp(r'(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
        _errorMessage = 'Phải chứa ít nhất 1 chữ hoa và 1 số';
        notifyListeners();
        return false;
      }

      final accountSettings = _defaultAccounts[selectedRole];

      // Validate tài khoản và mật khẩu
      if (accountSettings != null && 
          email == accountSettings['email'] && 
          password == accountSettings['password']) {
        
        // Cập nhật thông tin đăng nhập thành công
        _currentUser = UserModel(
          id: 'user_${selectedRole.name}',
          name: '${selectedRole.name.toUpperCase()} User',
          email: email,
          role: selectedRole,
        );

        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Email hoặc mật khẩu không chính xác cho vai trò này.';
        notifyListeners();
        return false;
      }

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