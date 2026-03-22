import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  UserRole? _selectedRole;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _staggerController;
  late List<Animation<double>> _staggerAnimations;

  // ── Màu sắc theo template HTML ──
  static const _coffeeDark = Color(0xFF361F1A);
  static const _coffeeMedium = Color(0xFF504442);
  static const _coffeeLight = Color(0xFFE4E2DE);
  static const _coffeeCream = Color(0xFFFBF9F5);
  static const _coffeeAccent = Color(0xFF1B6D24);
  static const _bgColor = Color(0xFFFBF9F5);

  // Dữ liệu vai trò theo template
  static const _roleData = <UserRole, _RoleInfo>{
    UserRole.manager: _RoleInfo(
      icon: Icons.bar_chart_rounded,
      title: 'Quản lý',
      subtitle: 'Quản lý menu, bàn & doanh thu',
      iconBgColor: _coffeeDark,
    ),
    UserRole.waiter: _RoleInfo(
      icon: Icons.card_giftcard_rounded,
      title: 'Nhân viên phục vụ',
      subtitle: 'Ghi order & phục vụ khách hàng',
      iconBgColor: _coffeeAccent,
    ),
    UserRole.barista: _RoleInfo(
      icon: Icons.science_rounded,
      title: 'Barista',
      subtitle: 'Pha chế & quản lý đơn hàng',
      iconBgColor: _coffeeMedium,
    ),
  };

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _staggerAnimations = List.generate(3, (index) {
      final start = index * 0.2;
      final end = start + 0.6;
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutBack),
      );
    });
    _staggerController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate() && _selectedRole != null) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
        _selectedRole!,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        switch (_selectedRole!) {
          case UserRole.manager:
            Navigator.pushReplacementNamed(context, AppRoutes.managerDashboard);
            break;
          case UserRole.waiter:
            Navigator.pushReplacementNamed(context, AppRoutes.waiterTables);
            break;
          case UserRole.barista:
            Navigator.pushReplacementNamed(context, AppRoutes.baristaOrders);
            break;
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Đăng nhập thất bại'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ── Decorative blur circles (giống template) ──
          Positioned(
            top: -96,
            right: -96,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: _coffeeLight.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -96,
            left: -96,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: _coffeeAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── Nội dung chính ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Column(
                    children: [
                      // ── Hero Section ──
                      _buildHeroSection(),

                      // ── Role Selection / Login Form ──
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.06),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              )),
                              child: child,
                            ),
                          );
                        },
                        child: _selectedRole == null
                            ? _buildRoleSelection()
                            : _buildLoginForm(),
                      ),

                      // ── Footer ──
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HERO SECTION ──
  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          // Logo - circle với ring giống template
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: _coffeeDark,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(54, 31, 26, 0.15),
                  blurRadius: 40,
                  offset: Offset(0, 12),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 8,
              ),
            ),
            child: const Icon(Icons.coffee_rounded, size: 44, color: Color(0xFFFBF9F5)),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'PRM393 Coffee',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _coffeeDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'HỆ THỐNG QUẢN LÝ QUÁN CÀ PHÊ',
            style: TextStyle(
              fontSize: 11,
              color: _coffeeMedium.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 24),

          // Divider line
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: _coffeeAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ── ROLE SELECTION ──
  Widget _buildRoleSelection() {
    return Padding(
      key: const ValueKey('RoleSelection'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            'Chọn vai trò để đăng nhập',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _coffeeDark,
            ),
          ),
          const SizedBox(height: 24),

          // Role cards
          ...UserRole.values.asMap().entries.map((entry) {
            final index = entry.key;
            final role = entry.value;
            final info = _roleData[role]!;

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(_staggerAnimations[index]),
              child: FadeTransition(
                opacity: _staggerAnimations[index],
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _RoleCard(
                    icon: info.icon,
                    title: info.title,
                    subtitle: info.subtitle,
                    iconBgColor: info.iconBgColor,
                    onTap: () {
                      setState(() {
                        _selectedRole = role;
                        _emailController.clear();
                        _passwordController.clear();
                      });
                    },
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── LOGIN FORM ──
  Widget _buildLoginForm() {
    final info = _roleData[_selectedRole]!;

    return Padding(
      key: const ValueKey('LoginForm'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF0EBE6)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(54, 31, 26, 0.04),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Row(
                children: [
                  // Back button
                  InkWell(
                    onTap: () {
                      setState(() => _selectedRole = null);
                      _staggerController.reset();
                      _staggerController.forward();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _coffeeMedium.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: _coffeeMedium, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _coffeeDark,
                          ),
                        ),
                        Text(
                          info.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: info.iconBgColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: info.iconBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(info.icon, color: Colors.white, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(label: 'Email', icon: Icons.email_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Email không đúng định dạng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(label: 'Mật khẩu', icon: Icons.lock_outline_rounded).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: const Color(0xFF9E7B5A),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải từ 6 ký tự trở lên';
                  }
                  if (!RegExp(r'(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                    return 'Mật khẩu phải chứa ít nhất 1 chữ hoa và 1 số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Login button
              Container(
                decoration: BoxDecoration(
                  color: info.iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: info.iconBgColor.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FOOTER ──
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Text(
            '© 2026 PRM393 Coffee Management System Group 3',
            style: TextStyle(
              fontSize: 11,
              color: _coffeeMedium.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'V 2.1.0 PREMIUM DESIGN',
            style: TextStyle(
              fontSize: 9,
              color: _coffeeMedium.withValues(alpha: 0.4),
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF504442), fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: const Color(0xFF504442), size: 20),
      filled: true,
      fillColor: const Color(0xFFFDFBF7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF0EBE6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF361F1A), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}

// ── Dữ liệu vai trò ──
class _RoleInfo {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;

  const _RoleInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
  });
}

// ── Role Card widget theo template HTML ──
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: iconBgColor.withValues(alpha: 0.08),
        highlightColor: const Color(0xFFF5F5DC),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF0EBE6),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(54, 31, 26, 0.04),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF361F1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF504442).withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: const Color(0xFF606C38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}