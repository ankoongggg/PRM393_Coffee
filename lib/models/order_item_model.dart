class OrderItemModel {
  final String menuItemId;
  final String menuItemName;
  final double unitPrice;
  int quantity;
  final String? note;
  bool isDone; // ✅ Thêm dòng này: Đánh dấu món đã pha xong chưa
  final String batchId; // ✅ Nhóm theo lần đặt (đặt thêm)

  OrderItemModel({
    required this.menuItemId,
    required this.menuItemName,
    required this.unitPrice,
    required this.quantity,
    this.note,
    this.isDone = false, // ✅ Mặc định món mới là chưa xong
    this.batchId = 'initial',
  });

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'menuItemName': menuItemName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'note': note,
      'isDone': isDone, // ✅ Lưu trạng thái xuống Firebase
      'batchId': batchId,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      menuItemId: map['menuItemId'] ?? '',
      menuItemName: map['menuItemName'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      note: map['note'],
      isDone: map['isDone'] ?? false, // ✅ Lấy trạng thái từ Firebase về
      batchId: map['batchId'] ?? 'initial',
    );
  }
}