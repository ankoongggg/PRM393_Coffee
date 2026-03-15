import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/app_theme.dart';
import '../data/coffee_data.dart';
import '../data/providers.dart';
import '../models/coffee_model.dart';
import '../widgets/coffee_card.dart';
import '../widgets/category_chip.dart';
import '../screens/cart_screen.dart';
import '../screens/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<CoffeeItem> get filteredCoffees {
    return CoffeeData.coffeeList.where((coffee) {
      final matchCategory =
          _selectedCategory == 'all' || coffee.categoryId == _selectedCategory;
      final matchSearch = coffee.name
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  List<CoffeeItem> get popularCoffees =>
      CoffeeData.coffeeList.where((c) => c.isPopular).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(cartProvider),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildCategorySection()),
          if (_searchQuery.isEmpty && _selectedCategory == 'all') ...[
            SliverToBoxAdapter(child: _buildSectionTitle('☕ Phổ biến nhất')),
            SliverToBoxAdapter(child: _buildPopularRow()),
          ],
          SliverToBoxAdapter(
            child: _buildSectionTitle(
              _searchQuery.isNotEmpty
                  ? '🔍 Kết quả tìm kiếm'
                  : '📋 Tất cả sản phẩm',
            ),
          ),
          _buildCoffeeGrid(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(CartProvider cartProvider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Chào buổi sáng! ☀️',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PRM393 Coffee',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            ),
            if (cartProvider.itemCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${cartProvider.itemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm cà phê...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textLight),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: CoffeeData.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = CoffeeData.categories[index];
          return CategoryChip(
            category: cat,
            isSelected: _selectedCategory == cat.id,
            onTap: () => setState(() => _selectedCategory = cat.id),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }

  Widget _buildPopularRow() {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: popularCoffees.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 160,
            child: CoffeeCard(
              coffee: popularCoffees[index],
              isHorizontal: true,
              onTap: () => _openDetail(popularCoffees[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoffeeGrid() {
    final coffees = filteredCoffees;
    if (coffees.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const Text('😔', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'Không tìm thấy sản phẩm',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => CoffeeCard(
            coffee: coffees[index],
            onTap: () => _openDetail(coffees[index]),
          ),
          childCount: coffees.length,
        ),
      ),
    );
  }

  void _openDetail(CoffeeItem coffee) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(coffee: coffee)),
    );
  }
}
