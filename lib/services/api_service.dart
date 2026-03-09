import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';  // MenuItem
import '../models/order.dart';       // Order, OrderItem, OrderStatus
import '../models/table.dart';       // CoffeeTable, TableStatus
import '../models/user.dart';        // User, UserRole

/// Lớp trung tâm gọi REST API.
///
/// Thay [baseUrl] bằng địa chỉ backend thật trước khi deploy.
/// Tất cả method đều ném [ApiException] khi server trả lỗi.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // TODO: đổi thành URL backend thật
  static const String baseUrl = 'https://api.prm393coffee.example.com';

  String? _authToken;

  /// Lưu JWT token sau khi login
  void setToken(String token) => _authToken = token;

  Map<String, String> get _headers => {
        'Content-Type':  'application/json',
        'Accept':        'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // ─────────────────────────────────────────────────────────────
  // Auth
  // ─────────────────────────────────────────────────────────────

  /// Đăng nhập, trả về [User] và lưu token nội bộ.
  Future<User> login(String email, String password) async {
    final res = await _post('/auth/login', {'email': email, 'password': password});
    _authToken = res['token'] as String?;
    return User.fromJson(res['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _post('/auth/logout', {});
    _authToken = null;
  }

  // ─────────────────────────────────────────────────────────────
  // Menu
  // ─────────────────────────────────────────────────────────────

  Future<List<MenuItem>> getMenuItems() async {
    final list = await _getList('/menu');
    return list.map(MenuItem.fromJson).toList();
  }

  Future<MenuItem> createMenuItem(MenuItem item) async {
    final res = await _post('/menu', item.toJson());
    return MenuItem.fromJson(res);
  }

  Future<MenuItem> updateMenuItem(MenuItem item) async {
    final res = await _put('/menu/${item.id}', item.toJson());
    return MenuItem.fromJson(res);
  }

  Future<void> deleteMenuItem(String id) => _delete('/menu/$id');

  // ─────────────────────────────────────────────────────────────
  // Tables
  // ─────────────────────────────────────────────────────────────

  Future<List<CoffeeTable>> getTables() async {
    final list = await _getList('/tables');
    return list.map(CoffeeTable.fromJson).toList();
  }

  Future<CoffeeTable> createTable(CoffeeTable table) async {
    final res = await _post('/tables', table.toJson());
    return CoffeeTable.fromJson(res);
  }

  Future<CoffeeTable> updateTable(CoffeeTable table) async {
    final res = await _put('/tables/${table.id}', table.toJson());
    return CoffeeTable.fromJson(res);
  }

  Future<void> deleteTable(String id) => _delete('/tables/$id');

  // ─────────────────────────────────────────────────────────────
  // Orders
  // ─────────────────────────────────────────────────────────────

  Future<List<Order>> getOrders() async {
    final list = await _getList('/orders');
    return list.map(Order.fromJson).toList();
  }

  Future<Order> getOrder(String id) async {
    final res = await _get('/orders/$id');
    return Order.fromJson(res);
  }

  Future<Order> createOrder(Order order) async {
    final res = await _post('/orders', order.toJson());
    return Order.fromJson(res);
  }

  Future<Order> updateOrderStatus(String id, OrderStatus status) async {
    final res = await _put('/orders/$id/status', {'status': status.name});
    return Order.fromJson(res);
  }

  // ─────────────────────────────────────────────────────────────
  // Revenue / Reports
  // ─────────────────────────────────────────────────────────────

  /// Trả về dữ liệu báo cáo thô (Map) – màn hình tự parse.
  Future<Map<String, dynamic>> getRevenueSummary({String? date}) async {
    final query = date != null ? '?date=$date' : '';
    return _get('/reports/revenue$query');
  }

  // ─────────────────────────────────────────────────────────────
  // HTTP helpers
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    debugPrint('[GET] $uri');
    final res = await http.get(uri, headers: _headers);
    return _handleResponse(res);
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    debugPrint('[GET-LIST] $uri');
    final res = await http.get(uri, headers: _headers);
    final body = _handleRaw(res);
    return (body as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl$path');
    debugPrint('[POST] $uri');
    final res = await http.post(uri, headers: _headers, body: jsonEncode(data));
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl$path');
    debugPrint('[PUT] $uri');
    final res = await http.put(uri, headers: _headers, body: jsonEncode(data));
    return _handleResponse(res);
  }

  Future<void> _delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    debugPrint('[DELETE] $uri');
    final res = await http.delete(uri, headers: _headers);
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, 'Delete failed: ${res.body}');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response res) {
    final body = _handleRaw(res);
    return body as Map<String, dynamic>;
  }

  dynamic _handleRaw(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, res.body);
  }
}

/// Exception ném ra khi server trả về status >= 400
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
