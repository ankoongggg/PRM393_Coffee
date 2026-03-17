// Chịu trách nhiệm: báo cáo doanh thu cơ bản (Manager)

import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../core/enums/order_status.dart';

class ReportData {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final DateTime reportDate;

  ReportData({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.reportDate,
  });
}

class ReportProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  double _totalRevenueToday = 0;
  int _totalOrdersToday = 0;
  late ReportData _todayReport;
  final Map<String, double> _revenueByDay = {};
  Map<String, int> _topSellingItems = {}; // item name => quantity sold
  bool _isLoading = false;
  String? _error;

  // Getters
  double get totalRevenueToday => _totalRevenueToday;
  int get totalOrdersToday => _totalOrdersToday;
  ReportData get todayReport => _todayReport;
  Map<String, double> get revenueByDay => Map.unmodifiable(_revenueByDay);
  Map<String, int> get topSellingItems => Map.unmodifiable(_topSellingItems);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─────────────────────────────────────────────────────────────
  // REPORT METHODS
  // ─────────────────────────────────────────────────────────────

  /// Lấy báo cáo tổng tất cả đơn hàng (Manager)
  Future<void> fetchTodayReport() async {
    _setLoading(true);
    try {
      final allOrders = await _firebaseService.fetchAllOrders();
      final today = DateTime.now();

      // Lọc tất cả orders đã hoàn thành (không lọc theo ngày)
      final completedOrders = allOrders.where((order) {
        return order.status == OrderStatus.completed || order.status == OrderStatus.served;
      }).toList();

      // Tính tổng doanh thu tất cả đơn
      _totalRevenueToday = completedOrders.fold<double>(0, (sum, order) => sum + order.totalAmount);
      _totalOrdersToday = completedOrders.length;

      // Tạo ReportData
      _todayReport = ReportData(
        totalRevenue: _totalRevenueToday,
        totalOrders: _totalOrdersToday,
        averageOrderValue: _totalOrdersToday > 0 ? _totalRevenueToday / _totalOrdersToday : 0,
        reportDate: today,
      );

      _error = null;
      print('✅ Báo cáo tổng: ${_todayReport.totalOrders} đơn, ${_todayReport.totalRevenue.toStringAsFixed(0)}đ');
    } catch (e) {
      _error = 'Lỗi fetch báo cáo: $e';
      print('❌ $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy báo cáo theo khoảng ngày
  Future<ReportData?> fetchReportByDateRange(DateTime from, DateTime to) async {
    _setLoading(true);
    try {
      final allOrders = await _firebaseService.fetchAllOrders();

      // Lọc orders trong khoảng ngày và đã hoàn thành
      final rangeOrders = allOrders.where((order) {
        final isInRange = order.createdAt.isAfter(from) && order.createdAt.isBefore(to);
        final isCompleted = order.status == OrderStatus.completed || order.status == OrderStatus.served;
        return isInRange && isCompleted;
      }).toList();

      // Tính tổng doanh thu
      final totalRevenue = rangeOrders.fold<double>(0, (sum, order) => sum + order.totalAmount);
      final totalOrders = rangeOrders.length;
      final averageOrderValue = (totalOrders > 0 ? totalRevenue / totalOrders : 0.0).toDouble();

      final report = ReportData(
        totalRevenue: totalRevenue,
        totalOrders: totalOrders,
        averageOrderValue: averageOrderValue,
        reportDate: from,
      );

      _error = null;
      print('✅ Báo cáo ${from.toString().split(' ')[0]} - ${to.toString().split(' ')[0]}: $totalOrders đơn, ${totalRevenue.toStringAsFixed(0)}đ');
      return report;
    } catch (e) {
      _error = 'Lỗi fetch báo cáo: $e';
      print('❌ $_error');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy top selling items (Barista/Kitchen stats)
  Future<void> fetchTopSellingItems() async {
    _setLoading(true);
    try {
      final allOrders = await _firebaseService.fetchAllOrders();

      // Group items by name and sum quantities
      _topSellingItems.clear();
      for (final order in allOrders) {
        if (order.status == OrderStatus.completed || order.status == OrderStatus.served) {
          for (final item in order.items) {
            _topSellingItems[item.menuItemName] = (_topSellingItems[item.menuItemName] ?? 0) + item.quantity;
          }
        }
      }

      // Sort by quantity (highest first)
      final sorted = _topSellingItems.entries.toList();
      sorted.sort((a, b) => b.value.compareTo(a.value));
      _topSellingItems = Map.fromEntries(sorted);

      _error = null;
      print('✅ Top selling items: ${_topSellingItems.keys.take(5).join(", ")}');
    } catch (e) {
      _error = 'Lỗi fetch top items: $e';
      print('❌ $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy doanh thu từng ngày trong 7 ngày gần nhất
  Future<void> fetchLast7DaysRevenue() async {
    _setLoading(true);
    try {
      final allOrders = await _firebaseService.fetchAllOrders();
      _revenueByDay.clear();

      // Lấy 7 ngày gần nhất
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        final dayOrders = allOrders.where((order) {
          final isInDay = order.createdAt.isAfter(startOfDay) && order.createdAt.isBefore(endOfDay);
          final isCompleted = order.status == OrderStatus.completed || order.status == OrderStatus.served;
          return isInDay && isCompleted;
        }).toList();

        final dayRevenue = dayOrders.fold<double>(0, (sum, order) => sum + order.totalAmount);
        final dayString = '${date.day}/${date.month}';
        _revenueByDay[dayString] = dayRevenue;
      }

      _error = null;
      print('✅ Doanh thu 7 ngày: ${_revenueByDay.length} ngày');
    } catch (e) {
      _error = 'Lỗi fetch doanh thu: $e';
      print('❌ $_error');
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER
  // ─────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
