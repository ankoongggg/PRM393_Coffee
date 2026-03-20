import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/app_theme.dart';
import '../models/coffee_model.dart';
import '../data/providers.dart';
// ✅ Import Provider Kho (Nhớ sửa đường dẫn cho đúng với project của bạn)
import '../providers/ingredient_provider.dart';

class CoffeeCard extends StatelessWidget {
  final CoffeeItem coffee;
  final VoidCallback onTap;
  final bool isHorizontal;

  const CoffeeCard({
    super.key,
    required this.coffee,
    required this.onTap,
    this.isHorizontal = false,
  });

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Lấy dữ liệu từ Kho
    final ingredients = context.watch<IngredientProvider>().ingredients;

    // 2. Thuật toán tính số ly tối đa (Nút thắt cổ chai)
    int maxAvailable = -1; // -1 là vô hạn (món không cài công thức)

    if (coffee.recipe.isNotEmpty) {
      double minCups = double.infinity;

      for (var entry in coffee.recipe.entries) {
        final reqQty = (entry.value as num).toDouble();

        try {
          // Tìm nguyên liệu trong kho theo ID
          final ing = ingredients.firstWhere((i) => i.id == entry.key);
          if (reqQty > 0) {
            final possibleCups = ing.stock / reqQty;
            if (possibleCups < minCups) {
              minCups = possibleCups;
            }
          }
        } catch (e) {
          // Nếu nguyên liệu bị xóa khỏi kho -> Hết hàng
          minCups = 0;
        }
      }
      maxAvailable = minCups == double.infinity ? 0 : minCups.floor();
    }

    // 3. Xác định trạng thái Hết hàng
    final bool isOutOfStock = !coffee.isAvailable || maxAvailable == 0;

    return GestureDetector(
      onTap: isOutOfStock ? null : onTap, // Khóa click nếu hết hàng
      child: Opacity(
        opacity: isOutOfStock ? 0.5 : 1.0, // ✅ Làm mờ toàn bộ thẻ nếu hết hàng
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1), // Fix cảnh báo vàng
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(context),
              Expanded(child: _buildInfo(context, maxAvailable, isOutOfStock)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    final isFav = favProvider.isFavorite(coffee.id);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Hero(
            tag: 'coffee_${coffee.id}',
            child: Image.network(
              coffee.imageUrl,
              height: isHorizontal ? 100 : 120, // Chỉnh lại độ cao ảnh một chút để nhường chỗ cho nút Thêm
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: isHorizontal ? 100 : 120,
                color: AppColors.primaryLight,
                child: const Icon(Icons.coffee, size: 40, color: Colors.white),
              ),
            ),
          ),
        ),
        if (coffee.isPopular)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🔥 Hot',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => favProvider.toggleFavorite(coffee),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
              ),
              child: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                size: 14,
                color: isFav ? Colors.red : AppColors.textLight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context, int maxAvailable, bool isOutOfStock) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đẩy nút Thêm xuống đáy
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                coffee.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: isHorizontal ? 13 : 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatPrice(coffee.price)}đ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: isHorizontal ? 13 : 14,
                    ),
                  ),
                  // ✅ Dòng báo số lượng ly còn lại
                  if (maxAvailable > 0)
                    Text(
                      'Còn: $maxAvailable',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold
                      ),
                    )
                  else if (isOutOfStock)
                    const Text(
                      'Hết hàng',
                      style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),

          // ✅ Nút "+ Thêm" chuẩn theo giao diện thiết kế
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32, // Độ cao nút thon gọn
            child: OutlinedButton.icon(
              onPressed: isOutOfStock ? null : onTap,
              icon: Icon(isOutOfStock ? Icons.block : Icons.add, size: 16),
              label: Text(
                isOutOfStock ? 'Hết món' : 'Thêm',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isOutOfStock ? Colors.grey : AppColors.primary,
                side: BorderSide(color: isOutOfStock ? Colors.grey[300]! : AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
                backgroundColor: isOutOfStock ? Colors.grey[100] : Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}