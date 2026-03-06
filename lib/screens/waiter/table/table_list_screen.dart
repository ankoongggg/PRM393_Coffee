import 'package:flutter/material.dart';
import '../../waiter/order/create_order_screen.dart';

class TableListScreen extends StatefulWidget {
  const TableListScreen({super.key});

  @override
  State<TableListScreen> createState() => _TableListScreenState();
}

class _TableListScreenState extends State<TableListScreen> {
  // TODO: replace with TableProvider.tables
  final List<Map<String, dynamic>> _tables = [
    {'id': '1', 'number': 1, 'capacity': 2, 'status': 'available'},
    {'id': '2', 'number': 2, 'capacity': 4, 'status': 'occupied', 'orderId': 'ORD002'},
    {'id': '3', 'number': 3, 'capacity': 4, 'status': 'available'},
    {'id': '4', 'number': 4, 'capacity': 6, 'status': 'reserved'},
    {'id': '5', 'number': 5, 'capacity': 2, 'status': 'occupied', 'orderId': 'ORD005'},
    {'id': '6', 'number': 6, 'capacity': 8, 'status': 'available'},
  ];

  Color _statusColor(String s) => switch (s) {
    'available' => const Color(0xFF27AE60),
    'occupied' => Colors.red,
    'reserved' => const Color(0xFFE67E22),
    _ => Colors.grey,
  };

  String _statusLabel(String s) => switch (s) {
    'available' => 'Trống',
    'occupied' => 'Đang phục vụ',
    'reserved' => 'Đã đặt trước',
    _ => s,
  };

  void _onTableTap(Map<String, dynamic> table) {
    final status = table['status'] as String;
    if (status == 'available') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CreateOrderScreen(tableId: table['id'], tableNumber: table['number'] as int),
      ));
    } else if (status == 'occupied') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bàn ${table['number']} - Đơn: ${table['orderId'] ?? 'N/A'}'),
          action: SnackBarAction(
            label: 'Theo dõi',
            onPressed: () => Navigator.pushNamed(context, '/waiter/order-tracking', arguments: table['orderId']),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bàn ${table['number']} đã được đặt trước'), backgroundColor: const Color(0xFFE67E22)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _tables.where((t) => t['status'] == 'available').length;
    final occupied = _tables.where((t) => t['status'] == 'occupied').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chọn Bàn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildLegendBar(available, occupied),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  Widget _buildLegendBar(int available, int occupied) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LegendItem(color: const Color(0xFF27AE60), label: 'Trống ($available)'),
          _LegendItem(color: Colors.red, label: 'Đang phục vụ ($occupied)'),
          _LegendItem(color: const Color(0xFFE67E22), label: 'Đã đặt'),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _tables.length,
      itemBuilder: (_, i) => _buildTableCard(_tables[i]),
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    final status = table['status'] as String;
    final color = _statusColor(status);
    final isAvailable = status == 'available';

    return Material(
      color: isAvailable ? color.withValues(alpha: 0.08) : color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      elevation: isAvailable ? 2 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onTableTap(table),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.table_bar, size: 36, color: color),
              const SizedBox(height: 8),
              Text('Bàn ${table['number']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 12, color: color.withValues(alpha: 0.7)),
                  const SizedBox(width: 3),
                  Text('${table['capacity']} chỗ', style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabel(status), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
              ),
              if (isAvailable) ...[
                const SizedBox(height: 6),
                const Text('Nhấn để tạo order', style: TextStyle(fontSize: 9, color: Color(0xFF4CAF50))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
    ],
  );
}
