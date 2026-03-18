import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import 'manager_navigation_bar.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  String _selectedRole = 'Tất cả';
  int _selectedNavIndex = 4; // ACCOUNT tab
  final _roles = ['Tất cả', 'Waiter', 'Barista'];

  // ✅ Mock dữ liệu nhân viên (TODO: tích hợp với Firebase sau)
  // Hiện AuthProvider chưa có method lấy list users, nên giữ mock trước
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
        'Waiter'  => const Color(0xFF1B6D24),
        'Barista' => const Color(0xFF003A76),
        _         => const Color(0xFF361F1A),
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
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F5),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFF0EBE6))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF361F1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quản lý Tài khoản',
            style: TextStyle(color: Color(0xFF361F1A), fontWeight: FontWeight.w800)),
        actions: [
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
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Thêm tài khoản', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditDialog(context),
      ),
      body: Column(
        children: [
          _buildSummaryBar(activeCount, waiterCount, baristaCount),
          _buildRoleFilter(),
          Expanded(child: _buildList()),
        ],
      ),
      bottomNavigationBar: buildManagerBottomNavigation(
        context: context,
        selectedIndex: _selectedNavIndex,
        onIndexChanged: (index) => setState(() => _selectedNavIndex = index),
      ),
    );
  }

  // ── Summary bar ───────────────────────────────────────────────

  Widget _buildSummaryBar(int active, int waiter, int barista) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem('${_accounts.length}', 'Tổng', const Color(0xFF361F1A)),
          _vDivider(),
          _StatItem('$active', 'Đang hoạt động', const Color(0xFF1B6D24)),
          _vDivider(),
          _StatItem('$waiter', 'Waiter', const Color(0xFF1B6D24)),
          _vDivider(),
          _StatItem('$barista', 'Barista', const Color(0xFF003A76)),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 32, color: const Color(0xFFE4E2DE));

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF361F1A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE4E2DE)),
              ),
              child: Text(
                role,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF504442),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF361F1A))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(acc['role'] as String,
                          style: TextStyle(fontSize: 10, color: roleColor, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.email_outlined, size: 14, color: Color(0xFF504442)),
                    const SizedBox(width: 6),
                    Text(acc['email'] as String,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF504442), fontWeight: FontWeight.w500)),
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
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF504442), fontWeight: FontWeight.w500)),
      ]);
}
