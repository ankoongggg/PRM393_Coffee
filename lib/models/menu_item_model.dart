class MenuItemModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final double price;
  final int quantity;
  final Map<String, dynamic>? recipe;
  final String imageURL; // Biến chính
  final bool isAvailable;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    this.quantity = 0,
    this.recipe,
    required this.imageURL,
    this.isAvailable = true,
  });

  // ✅ CÁCH FIX NHANH NHẤT:
  // Thêm Getter này để hỗ trợ các màn hình cũ vẫn đang gọi .imageUrl
  String get imageUrl => imageURL;

  // ✅ Hàm copyWith (Giữ nguyên)
  MenuItemModel copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    double? price,
    int? quantity,
    Map<String, dynamic>? recipe,
    String? imageURL,
    bool? isAvailable,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      recipe: recipe ?? this.recipe,
      imageURL: imageURL ?? this.imageURL,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  // ✅ Chuyển từ Map sang Model (Đã tối ưu handle image)
  factory MenuItemModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MenuItemModel(
      id: documentId,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      recipe: map['recipe'] != null ? Map<String, dynamic>.from(map['recipe']) : null,
      // Handle linh hoạt cả 3 kiểu đặt tên trên Firebase
      imageURL: map['imageURL'] ?? map['imageUrl'] ?? map['image_url'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  // ✅ Chuyển từ Model sang Map (Giữ nguyên)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'quantity': quantity,
      'recipe': recipe,
      'imageURL': imageURL,
      'isAvailable': isAvailable,
    };
  }
}