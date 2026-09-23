import 'customer_model.dart';

class CustomerAnalytics {
  const CustomerAnalytics({required this.customer, required this.orderCount, required this.totalSpent, this.lastPurchase});
  final CustomerModel customer; final int orderCount; final double totalSpent; final DateTime? lastPurchase;
}
