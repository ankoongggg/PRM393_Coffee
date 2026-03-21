import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../core/enums/user_role.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  // Hàm đăng nhập sử dụng dữ liệu từ Firestore
  Future<bool> login(String email, String password, UserRole selectedRole) async {
    _errorMessage = null;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty) {
        _errorMessage = 'Vui lòng nhập đầy đủ email và mật khẩu';
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _errorMessage = 'Mật khẩu phải từ 6 ký tự trở lên';
        notifyListeners();
        return false;
      }

      // Lấy danh sách users từ Firebase
      final firebaseService = FirebaseService();
      final users = await firebaseService.fetchAllUsers();

      // Mặc định tạm thời nhận pass Password123 nếu không có firebase auth
      // Tìm account hợp lệ có email và role khớp với lựa chọn
      final userAccount = users.where((u) => u['email'].toString().toLowerCase() == email.toLowerCase()).firstOrNull;

      if (userAccount == null) {
        _errorMessage = 'Tài khoản không tồn tại trên hệ thống.';
        notifyListeners();
        return false;
      }

      // Kiểm tra trạng thái hoạt động (Active)
      if (userAccount['active'] == false) {
         _errorMessage = 'Tài khoản đã bị khóa.';
         notifyListeners();
         return false;
      }

      // Kiểm tra xem Role có khớp với Role người dùng chọn khi đăng nhập không
      final dbRole = userAccount['role'].toString().toLowerCase();
      if (dbRole != selectedRole.name.toLowerCase()) {
        _errorMessage = 'Tài khoản này không có quyền truy cập với vai trò ${selectedRole.displayName}.';
        notifyListeners();
        return false;
      }
      
      // Kiểm tra mật khẩu (hỗ trợ đọc từ Firebase nếu user đã từng được cấp mật khẩu / đổi pass)
      final storedPassword = userAccount['password'] as String?;
      if (storedPassword != null && storedPassword.toString().isNotEmpty) {
        if (password != storedPassword) {
            _errorMessage = 'Mật khẩu không chính xác';
            notifyListeners();
            return false;
        }
      } else {
        // Fallback: Mặc định nếu trên Firebase chưa có field password, dùng chung pass test: Password123
        if (password != 'Password123' && password != '123456Aa') {
            _errorMessage = 'Mật khẩu không chính xác';
            notifyListeners();
            return false;
        }
      }

      // Cập nhật thông tin đăng nhập thành công
      _currentUser = UserModel(
        id: userAccount['id'],
        name: userAccount['name'] ?? 'No Name',
        email: email,
        role: selectedRole,
      );

      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = 'Lỗi hệ thống: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}