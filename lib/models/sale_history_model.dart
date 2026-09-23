import 'payment_mode.dart';

class SaleHistoryItem {
  const SaleHistoryItem({
    required this.productName,
    required this.quantityVariant,
    required this.quantity,
  });

  final String productName;
  final String quantityVariant;
  final double quantity;
}

class SaleHistoryOrder {
  const SaleHistoryOrder({
    required this.orderKey,
    required this.items,
    required this.totalAmount,
    required this.paymentMode,
    required this.createdAt,
  });

  /// The logical order identifier used for all delete operations.
  /// Mirrors the COALESCE(order_id, id) key used throughout the repository.
  final String orderKey;
  final List<SaleHistoryItem> items;
  final double totalAmount;
  final PaymentMode paymentMode;
  final DateTime createdAt;
}
