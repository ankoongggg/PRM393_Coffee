import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/table_provider.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ Fetch tables khi mở screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TableProvider>(context, listen: false).fetchTables();
    });
  }

  Color _statusColor(String status) => switch (status) {
    'available' => Colors.green,
    'occupied' => Colors.red,
    'reserved' => Colors.orange,
    _ => Colors.grey,
  };

  IconData _statusIcon(String status) => switch (status) {
    'available' => Icons.event_seat,
    'occupied' => Icons.people,
    'reserved' => Icons.bookmark,
    _ => Icons.table_bar,
  };

  String _statusLabel(String status) => switch (status) {
    'available' => 'Trống',
    'occupied' => 'Đang dùng',
    'reserved' => 'Đã đặt',
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<TableProvider>(
      builder: (context, tableProvider, child) {
        if (tableProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF6F4E37),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Quản lý Bàn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final tables = tableProvider.tables;
        final availableCount = tables.where((t) => t.status.toString().split('.').last == 'available').length;
        final occupiedCount = tables.where((t) => t.status.toString().split('.').last == 'occupied').length;

        return Scaffold(
          backgroundColor: const Color(0xFFFAF6F1),
          appBar: AppBar(
            backgroundColor: const Color(0xFF6F4E37),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Quản lý Bàn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => tableProvider.fetchTables(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF6F4E37),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Thêm bàn', style: TextStyle(color: Colors.white)),
            onPressed: () => _showAddEditDialog(context),
          ),
          body: Column(
            children: [
              _buildStatusBar(availableCount, occupiedCount, tables.length),
              Expanded(child: _buildTableGrid(tables)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(int available, int occupied, int total) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '$total', label: 'Tổng số bàn', color: const Color(0xFF6F4E37)),
          _divider(),
          _StatItem(value: '$available', label: 'Đang trống', color: Colors.green),
          _divider(),
          _StatItem(value: '$occupied', label: 'Đang phục vụ', color: Colors.red),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAddEditDialog(context, table: table),
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
                      color: color.withValues(alpha: 0.12),
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 13, color: Color(0xFF9E7B5A)),
                  const SizedBox(width: 3),
                  Text('${table.capacity} chỗ', style: const TextStyle(fontSize: 12, color: Color(0xFF9E7B5A))),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel(statusString), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {Map<String, dynamic>? table}) {
    final isEdit = table != null;
    final numCtrl = TextEditingController(text: isEdit ? '${table['number']}' : '');
    final capCtrl = TextEditingController(text: isEdit ? '${table['capacity']}' : '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Chỉnh sửa bàn ${table['number']}' : 'Thêm bàn mới'),
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
              decoration: const InputDecoration(labelText: 'Sức chứa (chỗ ngồi)', prefixIcon: Icon(Icons.people_outline)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6F4E37)),
            onPressed: () {
              // TODO: TableProvider.addTable / updateTable
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEdit ? 'Đã cập nhật bàn!' : 'Đã thêm bàn mới!'),
                  backgroundColor: const Color(0xFF6F4E37),
                ),
              );
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
      builder: (_) => AlertDialog(
        title: Text('Xóa Bàn ${table.tableNumber}?'),
        content: const Text('Bạn có chắc muốn xóa bàn này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // TODO: TableProvider.deleteTable(table.id)
              Navigator.pop(context);
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
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9E7B5A))),
        ],
      );
}

