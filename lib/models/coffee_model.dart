class CoffeeCategory {
  final String id;
  final String name;
  final String icon;

  const CoffeeCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class CoffeeItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryId;
  final double rating;
  final int reviewCount;
  final List<String> sizes;
  final bool isPopular;
  final bool isFavorite;

  const CoffeeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.sizes = const ['S', 'M', 'L'],
    this.isPopular = false,
    this.isFavorite = false,
  });

  CoffeeItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? categoryId,
    double? rating,
    int? reviewCount,
    List<String>? sizes,
    bool? isPopular,
    bool? isFavorite,
  }) {
    return CoffeeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      sizes: sizes ?? this.sizes,
      isPopular: isPopular ?? this.isPopular,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class CartItem {
  final CoffeeItem coffee;
  final String selectedSize;
  int quantity;

  CartItem({
    required this.coffee,
    required this.selectedSize,
    this.quantity = 1,
  });

  double get totalPrice => coffee.price * quantity;
}
