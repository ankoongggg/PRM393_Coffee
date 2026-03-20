class IngredientModel {
  final String id;
  final String name;      // Tên nguyên liệu (VD: Cam tươi, Cà phê hạt)
  final String unit;      // Đơn vị tính (VD: quả, gram, ml, lít)
  double stock;           // Số lượng tồn kho hiện tại
  final double minStock;  // Mức cảnh báo sắp hết (VD: Dưới 10 quả thì báo đỏ)

  IngredientModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.stock,
    this.minStock = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'stock': stock,
      'minStock': minStock,
    };
  }

  factory IngredientModel.fromMap(String id, Map<String, dynamic> map) {
    return IngredientModel(
      id: id,
      name: map['name'] ?? '',
      unit: map['unit'] ?? '',
      stock: (map['stock'] ?? 0).toDouble(),
      minStock: (map['minStock'] ?? 0).toDouble(),
    );
  }
}