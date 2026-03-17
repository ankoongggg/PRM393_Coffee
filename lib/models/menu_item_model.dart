class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isAvailable;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      // Backward compatibility: một số bản cũ lưu key `image_url`
      'imageUrl': imageUrl,
      'image_url': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
    };
  }
}