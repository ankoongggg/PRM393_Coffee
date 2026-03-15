// TODO: Implement TableProvider
// Chịu trách nhiệm: CRUD bàn (Manager), xem và chọn bàn (Waiter)

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/table_model.dart';
import '../core/enums/table_status.dart';
import '../services/firebase_service.dart';

class TableProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<TableModel> _tables = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _tableSubscription;

  // Getters
  List<TableModel> get tables => List.unmodifiable(_tables);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<TableModel> get availableTables =>
      _tables.where((t) => t.status == TableStatus.available).toList();

  TableProvider() {
    startTableListener();
  }

  void startTableListener() {
    _tableSubscription?.cancel();
    _setLoading(true);

    _tableSubscription = _firebaseService.getTablesStream().listen(
          (newList) {
        _tables = newList;
        _error = null;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _error = 'Lỗi stream: $e';
        _setLoading(false);
        notifyListeners();
      },
    );
  }

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
      await _firebaseService.addTable({
        'tableNumber': tableNumber,
        'capacity': capacity,
        'status': 'available', // Mặc định bàn mới là trống
        'createdAt': DateTime.now().toIso8601String(),
      });
      print('✅ Thêm bàn $tableNumber thành công');
    } catch (e) {
      _error = 'Lỗi thêm bàn: $e';
      print('❌ $_error');
      rethrow;
    }
  }

  /// Sửa bàn (Manager)
  Future<void> updateTable(String tableId, int tableNumber, int capacity) async {
    try {
      await _firebaseService.updateTable(tableId, {
        'tableNumber': tableNumber,
        'capacity': capacity,
      });
      print('✅ Cập nhật bàn ID: $tableId thành công');
    } catch (e) {
      _error = 'Lỗi sửa bàn: $e';
      print('❌ $_error');
      rethrow;
    }
  }

  /// Xóa bàn (Manager)
  Future<void> deleteTable(String tableId) async {
    try {
      await _firebaseService.deleteTable(tableId);
      print('✅ Xóa bàn ID: $tableId thành công');
    } catch (e) {
      _error = 'Lỗi xóa bàn: $e';
      print('❌ $_error');
      rethrow;
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

  @override
  void dispose() {
    _tableSubscription?.cancel();
    super.dispose();
  }
}
