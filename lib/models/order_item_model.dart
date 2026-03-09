class OrderItemModel {
  final String menuItemId;
  final String menuItemName;
  final double unitPrice;
  final int quantity;
  final String? note;

  const OrderItemModel({
    required this.menuItemId,
    required this.menuItemName,
    required this.unitPrice,
    required this.quantity,
    this.note,
  });

  double get subtotal => unitPrice * quantity;
}
