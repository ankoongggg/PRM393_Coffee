// TODO: Implement ReportProvider
// Chịu trách nhiệm: báo cáo doanh thu cơ bản (Manager)

import 'package:flutter/foundation.dart';

class ReportProvider extends ChangeNotifier {
  double _totalRevenueToday = 0;
  int _totalOrdersToday = 0;
  Map<String, double> _revenueByDay = {};

  double get totalRevenueToday => _totalRevenueToday;
  int get totalOrdersToday => _totalOrdersToday;
  Map<String, double> get revenueByDay =>
      Map.unmodifiable(_revenueByDay);

  // TODO: fetchTodayReport() - doanh thu + số đơn hôm nay
  // TODO: fetchReportByDateRange(DateTime from, DateTime to) - báo cáo theo khoảng ngày
  // TODO: fetchTopSellingItems() - món bán chạy nhất
}
