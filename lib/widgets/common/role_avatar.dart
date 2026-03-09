// TODO: Implement RoleAvatar
// Widget hiển thị avatar + tên + role của user đang đăng nhập
// Dùng trong AppBar hoặc Drawer header

import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class RoleAvatar extends StatelessWidget {
  final UserModel user;

  const RoleAvatar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // TODO: Build avatar với icon role + tên user + badge role
    return const Placeholder();
  }
}
