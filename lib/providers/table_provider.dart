// TODO: Implement TableProvider
// Chịu trách nhiệm: CRUD bàn (Manager), xem và chọn bàn (Waiter)

import 'package:flutter/foundation.dart';
import '../models/table_model.dart';
import '../core/enums/table_status.dart';
import '../services/firebase_service.dart';

class TableProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<TableModel> _tables = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TableModel> get tables => List.unmodifiable(_tables);
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  List<TableModel> get availableTables =>
      _tables.where((t) => t.status == TableStatus.available).toList();

  // ─────────────────────────────────────────────────────────────
  // FETCH TABLES
  // ─────────────────────────────────────────────────────────────

  /// Lấy danh sách tất cả bàn
  Future<void> fetchTables() async {
    _setLoading(true);
    try {
      _tables = await _firebaseService.fetchAllTables();
      _error = null;
      print('✅ Fetch ${_tables.length} bàn thành công');
    } catch (e) {
      _error = 'Lỗi fetch bàn: $e';
      print('❌ $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy danh sách bàn trống (for Waiter selecting table)
  Future<void> fetchAvailableTables() async {
    _setLoading(true);
    try {
      final allTables = await _firebaseService.fetchAllTables();
      _tables = allTables
          .where((t) => t.status == TableStatus.available)
          .toList();
      _error = null;
      print('✅ Fetch ${_tables.length} bàn trống');
    } catch (e) {
      _error = 'Lỗi fetch bàn trống: $e';
      print('❌ $_error');
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TABLE MANAGEMENT (Manager)
  // ─────────────────────────────────────────────────────────────

  /// Thêm bàn mới (Manager)
  Future<void> addTable(int tableNumber, int capacity) async {
    try {
      // TODO: Implement create table in Firestore
      print('TODO: Add table to Firestore');
      await fetchTables();
    } catch (e) {
      _error = 'Lỗi thêm bàn: $e';
      print('❌ $_error');
    }
  }

  /// Sửa bàn (Manager)
  Future<void> updateTable(String tableId, int capacity) async {
    try {
      // TODO: Implement update table in Firestore
      print('TODO: Update table in Firestore');
      await fetchTables();
    } catch (e) {
      _error = 'Lỗi sửa bàn: $e';
      print('❌ $_error');
    }
  }

  /// Xóa bàn (Manager)
  Future<void> deleteTable(String tableId) async {
    try {
      // TODO: Implement delete table in Firestore
      print('TODO: Delete table from Firestore');
      await fetchTables();
    } catch (e) {
      _error = 'Lỗi xóa bàn: $e';
      print('❌ $_error');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TABLE STATUS (Waiter/Barista)
  // ─────────────────────────────────────────────────────────────

  /// Đánh dấu bàn là "occupied" khi Waiter chọn bàn tạo order
  Future<void> setTableOccupied(String tableId, String orderId) async {
    try {
      await _firebaseService.updateTableStatus(
        tableId,
        'occupied',
        currentOrderId: orderId,
      );
      print('✅ Bàn $tableId đánh dấu occupied');
      await fetchTables();
    } catch (e) {
      _error = 'Lỗi cập nhật bàn: $e';
      print('❌ $_error');
    }
  }

  /// Đánh dấu bàn là "waiting" khi order đã gửi đến Barista (chờ phục vụ)
  Future<void> setTableWaiting(String tableId, String orderId) async {
    try {
      await _firebaseService.updateTableStatus(
        tableId,
        'waiting',
        currentOrderId: orderId,
      );
      print('✅ Bàn $tableId đánh dấu waiting');
      await fetchTables();
    } catch (e) {
      _error = 'Lỗi cập nhật bàn: $e';
      print('❌ $_error');
    }
  }

  /// Đánh dấu bàn là "available" khi hoàn thành đơn (Waiter)
  Future<void> setTableAvailable(String tableId) async {
    try {
      await _firebaseService.updateTableStatus(
        tableId,
        'available',
        currentOrderId: null,
      );
      print('✅ Bàn $tableId trở lại available');
      await fetchTables();
    } catch (e) {
      _error = 'Lỗi cập nhật bàn: $e';
      print('❌ $_error');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
