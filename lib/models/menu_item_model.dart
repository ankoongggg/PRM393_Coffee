class MenuItemModel {
  final String id;
  final String name;
  final String category;
  final String description; // ✅ Thêm lại
  final double price;
  final int quantity; // Số lượng tính toán từ kho
  final Map<String, dynamic>? recipe;
  final String imageURL; // ✅ Thống nhất dùng hoa 3 chữ cuối
  final bool isAvailable; // ✅ Thêm lại

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

  // ✅ Hàm copyWith rất quan trọng để cập nhật quantity động
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

  // ✅ Chuyển từ Map (Firebase) sang Model
  factory MenuItemModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MenuItemModel(
      id: documentId,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      // Lưu ý: quantity lấy từ Firebase chỉ là số khởi tạo, sau đó sẽ bị ghi đè bởi logic kho
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      recipe: map['recipe'] != null ? Map<String, dynamic>.from(map['recipe']) : null,
      imageURL: map['imageURL'] ?? map['imageUrl'] ?? '', // Handle cả 2 trường hợp
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  // ✅ Chuyển từ Model sang Map để lưu lên Firebase
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