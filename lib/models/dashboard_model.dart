import 'payment_mode.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.salesRevenue,
    required this.profit,
    required this.orderCount,
    required this.averageOrderValue,
  });

  final double salesRevenue;
  final double profit;
  final int orderCount;
  final double averageOrderValue;

  bool get hasOrders => orderCount > 0;
}

class TopSellingOilToday {
  const TopSellingOilToday({
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  final String productName;
  final double quantitySold;
  final double revenue;
}

class RecentOrderSummary {
  const RecentOrderSummary({
    required this.oilSummary,
    required this.time,
    required this.totalAmount,
    required this.paymentMode,
  });

  final String oilSummary;
  final String time;
  final double totalAmount;
  final PaymentMode paymentMode;
}
