/// Role của người dùng trong hệ thống.
enum UserRole {
  manager,
  waiter,
  barista;

  String get displayName => switch (this) {
        UserRole.manager  => 'Quản lý',
        UserRole.waiter   => 'Nhân viên phục vụ',
        UserRole.barista  => 'Barista',
      };

  String get icon => switch (this) {
        UserRole.manager  => '👔',
        UserRole.waiter   => '🧑‍💼',
        UserRole.barista  => '☕',
      };

  static UserRole fromString(String value) =>
      UserRole.values.firstWhere(
        (e) => e.name == value,
        orElse: () => UserRole.waiter,
      );
}

/// Thông tin người dùng trả về từ API sau khi login.
class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: UserRole.fromString(json['role'] as String? ?? 'waiter'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
      };
}
