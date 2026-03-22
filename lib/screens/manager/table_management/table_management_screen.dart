import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/table_provider.dart';
import '../../../routes/app_routes.dart';
import '../manager_navigation_bar.dart';
import 'table_orders_screen.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  int _selectedNavIndex = 1; // TABLES tab

  @override
  void initState() {
    super.initState();
    // Bắt đầu lắng nghe Stream khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TableProvider>(context, listen: false).startTableListener();
    });
  }

  Color _statusColor(String status) => switch (status) {
    'available' => Colors.green,
    'occupied' => Colors.red,
    'reserved' => Colors.orange,
    'waiting' => Colors.blue,
    _ => Colors.grey,
  };

  IconData _statusIcon(String status) => switch (status) {
    'available' => Icons.event_seat,
    'occupied' => Icons.people,
    'reserved' => Icons.bookmark,
    'waiting' => Icons.hourglass_empty,
    _ => Icons.table_bar,
  };

  String _statusLabel(String status) => switch (status) {
    'available' => 'Trống',
    'occupied' => 'Đang dùng',
    'reserved' => 'Đã đặt',
    'waiting' => 'Chờ món',
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<TableProvider>(
      builder: (context, tableProvider, child) {
        // Chỉ hiện loading ở lần đầu tiên khi chưa có dữ liệu
        if (tableProvider.isLoading && tableProvider.tables.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF6F4E37),
              title: const Text('Quản lý Bàn', style: TextStyle(color: Colors.white)),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final tables = tableProvider.tables;
        final availableCount = tables.where((t) => t.status.toString().split('.').last == 'available').length;
        final occupiedCount = tables.where((t) => t.status.toString().split('.').last == 'occupied').length;

        return Scaffold(
          backgroundColor: const Color(0xFFFBF9F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBF9F5),
            elevation: 0,
            automaticallyImplyLeading: false,
            shape: const Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
            title: const Text('Quản lý Bàn', style: TextStyle(color: Color(0xFF361F1A), fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF361F1A)),
                onPressed: () => tableProvider.startTableListener(),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFF361F1A)),
                tooltip: 'Đăng xuất',
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF361F1A),
            elevation: 4,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Thêm bàn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => _showAddEditDialog(context),
          ),
          body: Column(
            children: [
              _buildStatusBar(availableCount, occupiedCount, tables.length),
              if (tableProvider.error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(tableProvider.error!, style: const TextStyle(color: Colors.red)),
                ),
              Expanded(child: _buildTableGrid(tables)),
            ],
          ),
          bottomNavigationBar: buildManagerBottomNavigation(
            context: context,
            selectedIndex: _selectedNavIndex,
            onIndexChanged: (index) => setState(() => _selectedNavIndex = index),
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(int available, int occupied, int total) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '$total', label: 'Tổng số bàn', color: const Color(0xFF361F1A)),
          _divider(),
          _StatItem(value: '$available', label: 'Đang trống', color: Colors.green),
          _divider(),
          _StatItem(value: '$occupied', label: 'Đang dùng', color: Colors.red),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 36, width: 1, color: const Color(0xFFE8D5C0));

  Widget _buildTableGrid(List tables) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: tables.length,
      itemBuilder: (_, i) => _buildTableCard(tables[i]),
    );
  }

  Widget _buildTableCard(dynamic table) {
    final statusString = table.status.toString().split('.').last;
    final color = _statusColor(statusString);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TableOrdersScreen(
              tableId: table.id,
              tableNumber: table.tableNumber,
              capacity: table.capacity,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_statusIcon(statusString), color: color, size: 22),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF9E7B5A)),
                    onSelected: (v) {
                      if (v == 'edit') _showAddEditDialog(context, table: table);
                      if (v == 'delete') _confirmDelete(context, table);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Chỉnh sửa')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Xóa', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Bàn ${table.tableNumber}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF361F1A)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 14, color: Color(0xFF504442)),
                  const SizedBox(width: 4),
                  Text('${table.capacity} chỗ', style: const TextStyle(fontSize: 12, color: Color(0xFF504442), fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel(statusString), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showAddEditDialog(BuildContext context, {dynamic table}) {
    final isEdit = table != null;
    final numCtrl = TextEditingController(text: isEdit ? '${table.tableNumber}' : '');
    final capCtrl = TextEditingController(text: isEdit ? '${table.capacity}' : '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit ? 'Chỉnh sửa bàn ${table.tableNumber}' : 'Thêm bàn mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số bàn', prefixIcon: Icon(Icons.table_bar)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sức chứa', prefixIcon: Icon(Icons.people_outline)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6F4E37)),
            onPressed: () async {
              final number = int.tryParse(numCtrl.text) ?? 0;
              final capacity = int.tryParse(capCtrl.text) ?? 0;

              if (number > 0 && capacity > 0) {
                final provider = Provider.of<TableProvider>(context, listen: false);
                try {
                  if (isEdit) {
                    await provider.updateTable(table.id, number, capacity);
                  } else {
                    await provider.addTable(number, capacity);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: Text(isEdit ? 'Lưu' : 'Thêm', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic table) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Xóa Bàn ${table.tableNumber}?'),
        content: const Text('Bạn có chắc muốn xóa bàn này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await Provider.of<TableProvider>(context, listen: false).deleteTable(table.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF504442), fontWeight: FontWeight.w500)),
    ],
  );
}