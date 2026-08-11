class CartItem {
  CartItem({
    required this.productId,
    required this.productName,
    required this.variant,
    required this.quantity,
    required this.unitPriceSnapshot,
    required this.costPriceSnapshot,
  });

  final String productId;
  final String productName;
  final String variant;
  int quantity;
  final double unitPriceSnapshot;
  final double costPriceSnapshot;

  double get lineTotal => unitPriceSnapshot * quantity;
}
