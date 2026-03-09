// TODO: Implement TableProvider
// Chịu trách nhiệm: CRUD bàn (Manager), xem và chọn bàn (Waiter)

import 'package:flutter/foundation.dart';
import '../models/table_model.dart';
import '../core/enums/table_status.dart';

class TableProvider extends ChangeNotifier {
  List<TableModel> _tables = [];

  List<TableModel> get tables => List.unmodifiable(_tables);
  List<TableModel> get availableTables =>
      _tables.where((t) => t.status == TableStatus.available).toList();

  // TODO: fetchTables() - lấy danh sách bàn
  // TODO: addTable(TableModel table) - thêm bàn mới (Manager)
  // TODO: updateTable(TableModel table) - sửa thông tin bàn (Manager)
  // TODO: deleteTable(String id) - xóa bàn (Manager)
  // TODO: setTableOccupied(String id, String orderId) - Waiter chọn bàn khi tạo order
  // TODO: setTableAvailable(String id) - trả bàn về trạng thái trống
}
