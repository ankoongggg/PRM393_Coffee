import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/app_routes.dart';
import '../../providers/report_provider.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _selectedNavIndex = 3; // STATS tab selected by default

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      reportProvider.fetchTodayReport();
      reportProvider.fetchLast7DaysRevenue();
      reportProvider.fetchTopSellingItems();
    });
  }

  // Color constants
  static const Color _bgColor = Color(0xFFFBF9F5);
  static const Color _primary = Color(0xFF361F1A);
  static const Color _primaryDark = Color(0xFF4E342E);
  static const Color _secondary = Color(0xFF1B6D24);
  static const Color _tertiary = Color(0xFF00244F);
  static const Color _surfaceContainer = Color(0xFFEFEEEA);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFF1B1C1A);
  static const Color _onSurfaceVariant = Color(0xFF504442);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        return Scaffold(
          backgroundColor: _bgColor,
          body: Column(
            children: [
              // ── Fixed Header ──
              _buildHeader(),
              
              // ── Main Content ──
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        _buildSummaryCards(reportProvider),
                        const SizedBox(height: 24),
                        
                        // Revenue Chart
                        _buildRevenueSection(reportProvider),
                        const SizedBox(height: 24),
                        
                        // Top Selling Items
                        _buildTopSellingItems(reportProvider),
                        const SizedBox(height: 24),
                        
                        // Quick Actions
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // ── Bottom Navigation ──
          bottomNavigationBar: _buildBottomNavigation(),
        );
      },
    );
  }

  // ── HEADER ──
  Widget _buildHeader() {
    return Container(
      color: _bgColor,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo and Title
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.coffee_rounded, size: 20, color: _bgColor),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Roastery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'MANAGER',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: _onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Notification and Profile
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: _primary, size: 24),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: _primary, size: 22),
                  tooltip: 'Đăng xuất',
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── SUMMARY CARDS ──
  Widget _buildSummaryCards(ReportProvider reportProvider) {
    final formatPrice = (double amount) =>
        amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SummaryCard(
            icon: Icons.payments_rounded,
            label: 'DAILY REVENUE',
            value: '${formatPrice(reportProvider.totalRevenueToday)}₫',
            trend: '+12.5%',
            trendColor: _secondary,
            iconBgColor: const Color(0xFFf0e6e0),
            iconColor: _primary,
          ),
          const SizedBox(width: 16),
          _SummaryCard(
            icon: Icons.shopping_bag_rounded,
            label: 'ORDERS',
            value: reportProvider.totalOrdersToday.toString(),
            iconBgColor: const Color(0xFFe8f5e9),
            iconColor: _secondary,
          ),
          const SizedBox(width: 16),
          _SummaryCard(
            icon: Icons.receipt_long_rounded,
            label: 'AVG. ORDER',
            value: '${formatPrice(reportProvider.todayReport.averageOrderValue)}₫',
            iconBgColor: const Color(0xFFe3f2fd),
            iconColor: _tertiary,
          ),
        ],
      ),
    );
  }

  // ── REVENUE SECTION ──
  Widget _buildRevenueSection(ReportProvider reportProvider) {
    final revenueByDay = reportProvider.revenueByDay;
    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final maxRevenue = revenueByDay.values.isEmpty ? 1 : revenueByDay.values.reduce((a, b) => a > b ? a : b);
    final today = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Doanh thu 7 ngày',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lượt doanh thu tuần qua (VND)',
                    style: TextStyle(
                      fontSize: 12,
                      color: _onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TUẦN NÀY',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: _onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Chart
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final dateKey = dayLabels[index];
                final revenue = revenueByDay[dateKey] ?? 0.0;
                final height = maxRevenue > 0 ? (revenue / maxRevenue).clamp(0.1, 1.0) : 0.1;
                final isToday = today.weekday - 2 == index || (today.weekday == 7 && index == 6);
                return _ChartBar(
                  height: height,
                  day: isToday ? '$dateKey (Nay)' : dateKey,
                  isActive: isToday,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── TOP SELLING ITEMS ──
  Widget _buildTopSellingItems(ReportProvider reportProvider) {
    final topItems = reportProvider.topSellingItems.entries.toList();
    topItems.sort((a, b) => b.value.compareTo(a.value));
    final displayItems = topItems.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top món bán chạy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _primary,
              ),
            ),
            Text(
              'Xem tất cả',
              style: TextStyle(
                fontSize: 12,
                color: _onSurfaceVariant.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(54, 31, 26, 0.04),
                blurRadius: 12,
              )
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < displayItems.length; i++) ...
              [
                _TopItemRow(
                  name: displayItems[i].key,
                  quantity: displayItems[i].value,
                ),
                if (i < displayItems.length - 1)
                  Divider(
                    height: 0.5,
                    color: _onSurfaceVariant.withOpacity(0.1),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── QUICK ACTIONS ──
  Widget _buildQuickActions() {
    return Column(
      children: [
        Text(
          'Quản lý nhanh',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _primary.withOpacity(0.7),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final items = [
              ('Menu', Icons.restaurant_menu_rounded, _primary, AppRoutes.managerMenu),
              ('Bàn', Icons.table_bar_rounded, _secondary, AppRoutes.managerTables),
              ('Đơn hàng', Icons.receipt_long_rounded, _tertiary, AppRoutes.managerOrders),
              ('Báo cáo', Icons.bar_chart_rounded, _primaryDark, AppRoutes.managerRevenue),
            ];
            
            final (label, icon, color, route) = items[index];
            
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, route),
              child: Container(
                decoration: BoxDecoration(
                  color: _surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(54, 31, 26, 0.02),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── BOTTOM NAVIGATION ──
  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: _bgColor,
        border: Border(
          top: BorderSide(
            color: _onSurface.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.restaurant_menu_rounded,
                label: 'MENU',
                isActive: _selectedNavIndex == 0,
                onTap: () {
                  setState(() => _selectedNavIndex = 0);
                  Navigator.pushNamed(context, AppRoutes.managerMenu);
                },
              ),
              _NavItem(
                icon: Icons.table_bar_rounded,
                label: 'TABLES',
                isActive: _selectedNavIndex == 1,
                onTap: () {
                  setState(() => _selectedNavIndex = 1);
                  Navigator.pushNamed(context, AppRoutes.managerTables);
                },
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'ORDERS',
                isActive: _selectedNavIndex == 2,
                onTap: () {
                  setState(() => _selectedNavIndex = 2);
                  Navigator.pushNamed(context, AppRoutes.managerOrders);
                },
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'STATS',
                isActive: _selectedNavIndex == 3,
                onTap: () {
                  setState(() => _selectedNavIndex = 3);
                },
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'ACCOUNT',
                isActive: _selectedNavIndex == 4,
                onTap: () {
                  setState(() => _selectedNavIndex = 4);
                  Navigator.pushNamed(context, AppRoutes.managerAccounts);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── HELPER WIDGETS ──

// Summary Card Widget
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? trend;
  final Color? trendColor;
  final Color iconBgColor;
  final Color iconColor;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBgColor,
    required this.iconColor,
    this.trend,
    this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(54, 31, 26, 0.04),
              blurRadius: 12,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Trend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (trendColor ?? Colors.green).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trend!,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: trendColor ?? Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Label
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Color(0xFF504442),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            
            // Value
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF361F1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chart Bar Widget
class _ChartBar extends StatelessWidget {
  final double height;
  final String day;
  final bool isActive;

  const _ChartBar({
    required this.height,
    required this.day,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Space filler
        Expanded(
          flex: ((1.0 - height) * 100).toInt(),
          child: const SizedBox.expand(),
        ),
        // Bar
        Expanded(
          flex: (height * 100).toInt(),
          child: SizedBox(
            width: 24,
            child: Container(
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF4E342E), Color(0xFF361F1A)],
                      )
                    : null,
                color: isActive ? null : const Color(0xFFf0e6e0),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                boxShadow: isActive
                    ? [
                        const BoxShadow(
                          color: Color.fromRGBO(54, 31, 26, 0.15),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        )
                      ]
                    : [],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFF361F1A) : const Color(0xFF504442),
          ),
        ),
      ],
    );
  }
}

// Top Item Row Widget
class _TopItemRow extends StatelessWidget {
  final String name;
  final int quantity;

  const _TopItemRow({
    required this.name,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF361F1A),
            ),
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF504442),
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom Nav Item Widget
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? const Color(0xFF361F1A) : const Color(0xFF504442).withOpacity(0.6),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF361F1A) : const Color(0xFF504442).withOpacity(0.6),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(54, 31, 26, 0.04), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Spacer(),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF361F1A))),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF504442), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
