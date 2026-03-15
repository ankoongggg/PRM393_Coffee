import 'package:flutter/material.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  String _selectedRole = 'Tất cả';
  final _roles = ['Tất cả', 'Waiter', 'Barista'];

  // TODO: thay bằng dữ liệu từ API / AuthProvider
  final List<Map<String, dynamic>> _accounts = [
    {'id': 'USR001', 'name': 'Nguyễn An',   'email': 'an@coffee.vn',   'role': 'Waiter',   'active': true},
    {'id': 'USR002', 'name': 'Trần Bình',   'email': 'binh@coffee.vn', 'role': 'Waiter',   'active': true},
    {'id': 'USR003', 'name': 'Lê Chi',      'email': 'chi@coffee.vn',  'role': 'Barista',  'active': true},
    {'id': 'USR004', 'name': 'Phạm Dũng',   'email': 'dung@coffee.vn', 'role': 'Barista',  'active': false},
    {'id': 'USR005', 'name': 'Hoàng Em',    'email': 'em@coffee.vn',   'role': 'Waiter',   'active': true},
  ];

  List<Map<String, dynamic>> get _filtered => _selectedRole == 'Tất cả'
      ? _accounts
      : _accounts.where((a) => a['role'] == _selectedRole).toList();

  Color _roleColor(String role) => switch (role) {
        'Waiter'  => const Color(0xFF2E7D32),
        'Barista' => const Color(0xFF1565C0),
        _         => const Color(0xFF6F4E37),
      };

  IconData _roleIcon(String role) => switch (role) {
        'Waiter'  => Icons.room_service,
        'Barista' => Icons.local_cafe,
        _         => Icons.person,
      };

  @override
  Widget build(BuildContext context) {
    final activeCount  = _accounts.where((a) => a['active'] == true).length;
    final waiterCount  = _accounts.where((a) => a['role'] == 'Waiter').length;
    final baristaCount = _accounts.where((a) => a['role'] == 'Barista').length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F4E37),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quản lý Tài khoản',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6F4E37),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Thêm tài khoản', style: TextStyle(color: Colors.white)),
        onPressed: () => _showAddEditDialog(context),
      ),
      body: Column(
        children: [
          _buildSummaryBar(activeCount, waiterCount, baristaCount),
          _buildRoleFilter(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // ── Summary bar ───────────────────────────────────────────────

  Widget _buildSummaryBar(int active, int waiter, int barista) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem('${_accounts.length}', 'Tổng', const Color(0xFF6F4E37)),
          _vDivider(),
          _StatItem('$active', 'Đang hoạt động', const Color(0xFF27AE60)),
          _vDivider(),
          _StatItem('$waiter', 'Waiter', const Color(0xFF2E7D32)),
          _vDivider(),
          _StatItem('$barista', 'Barista', const Color(0xFF1565C0)),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 32, color: const Color(0xFFE8D5C0));

  // ── Role filter ───────────────────────────────────────────────

  Widget _buildRoleFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _roles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final role = _roles[i];
          final selected = role == _selectedRole;
          return GestureDetector(
            onTap: () => setState(() => _selectedRole = role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF6F4E37) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6F4E37)),
              ),
              child: Text(
                role,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF6F4E37),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Account list ──────────────────────────────────────────────

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline, size: 48, color: Color(0xFFD4A864)),
          SizedBox(height: 8),
          Text('Không có tài khoản', style: TextStyle(color: Color(0xFF9E7B5A))),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: _filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildAccountCard(_filtered[i]),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> acc) {
    final roleColor = _roleColor(acc['role'] as String);
    final isActive  = acc['active'] as bool;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_roleIcon(acc['role'] as String), color: roleColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(acc['name'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C1A0E))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(acc['role'] as String,
                          style: TextStyle(fontSize: 10, color: roleColor, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.email_outlined, size: 12, color: Color(0xFF9E7B5A)),
                    const SizedBox(width: 4),
                    Text(acc['email'] as String,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9E7B5A))),
                  ]),
                ],
              ),
            ),
            // Status toggle + menu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Switch(
                  value: isActive,
                  activeThumbColor: const Color(0xFF27AE60),
                  activeTrackColor: const Color(0xFF27AE60).withValues(alpha: 0.3),
                  onChanged: (v) {
                    // TODO: AuthProvider.toggleAccount
                    setState(() => acc['active'] = v);
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, size: 18, color: Color(0xFF9E7B5A)),
                  onSelected: (val) {
                    if (val == 'edit')   _showAddEditDialog(context, account: acc);
                    if (val == 'reset')  _showResetPasswordDialog(context, acc);
                    if (val == 'delete') _confirmDelete(context, acc);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit',
                        child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Chỉnh sửa')])),
                    const PopupMenuItem(value: 'reset',
                        child: Row(children: [Icon(Icons.lock_reset, size: 16, color: Color(0xFFE67E22)), SizedBox(width: 8), Text('Đặt lại mật khẩu', style: TextStyle(color: Color(0xFFE67E22)))])),
                    const PopupMenuItem(value: 'delete',
                        child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Xóa tài khoản', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────

  void _showAddEditDialog(BuildContext context, {Map<String, dynamic>? account}) {
    final isEdit     = account != null;
    final nameCtrl   = TextEditingController(text: isEdit ? account['name']  as String : '');
    final emailCtrl  = TextEditingController(text: isEdit ? account['email'] as String : '');
    final passCtrl   = TextEditingController();
    String selectedRole = isEdit ? account['role'] as String : 'Waiter';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(isEdit ? 'Chỉnh sửa tài khoản' : 'Thêm tài khoản mới'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              if (!isEdit) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Vai trò',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: ['Waiter', 'Barista'].map((r) =>
                    DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setDlg(() => selectedRole = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6F4E37)),
              onPressed: () {
                // TODO: AuthProvider.addAccount / updateAccount
                if (!isEdit) {
                  setState(() => _accounts.add({
                    'id':     'USR${_accounts.length + 1}',
                    'name':   nameCtrl.text,
                    'email':  emailCtrl.text,
                    'role':   selectedRole,
                    'active': true,
                  }));
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isEdit ? 'Đã cập nhật tài khoản!' : 'Đã thêm tài khoản mới!'),
                  backgroundColor: const Color(0xFF6F4E37),
                ));
              },
              child: Text(isEdit ? 'Lưu' : 'Thêm',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, Map<String, dynamic> acc) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Đặt lại mật khẩu\n${acc['name']}'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mật khẩu mới',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE67E22)),
            onPressed: () {
              // TODO: AuthProvider.resetPassword
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Đã đặt lại mật khẩu!'),
                backgroundColor: Color(0xFFE67E22),
              ));
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> acc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xóa tài khoản "${acc['name']}"?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // TODO: AuthProvider.deleteAccount
              setState(() => _accounts.removeWhere((a) => a['id'] == acc['id']));
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatItem(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E7B5A))),
      ]);
}
