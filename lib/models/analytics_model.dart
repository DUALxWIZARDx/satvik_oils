import 'payment_mode.dart';

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.revenue,
    required this.profit,
    required this.orders,
  });
  final double revenue, profit;
  final int orders;
  double get aov => orders == 0 ? 0 : revenue / orders;
}

class AnalyticsDay {
  const AnalyticsDay({required this.date, required this.summary});
  final DateTime date;
  final AnalyticsSummary summary;
}

class ProductPerformance {
  const ProductPerformance({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.profit,
    required this.litresSold,
    required this.variants,
  });
  final String productId, name;
  final double quantity, revenue, profit, litresSold;
  final List<VariantPerformance> variants;
}

class VariantPerformance {
  const VariantPerformance({
    required this.variant,
    required this.quantity,
    required this.revenue,
    required this.profit,
  });
  final String variant;
  final double quantity, revenue, profit;
}

class PaymentPerformance {
  const PaymentPerformance({
    required this.mode,
    required this.revenue,
    required this.orders,
  });
  final PaymentMode mode;
  final double revenue;
  final int orders;
}

class AnalyticsReport {
  const AnalyticsReport({
    required this.summary,
    required this.previous,
    required this.days,
    required this.products,
    required this.payments,
  });
  final AnalyticsSummary summary, previous;
  final List<AnalyticsDay> days;
  final List<ProductPerformance> products;
  final List<PaymentPerformance> payments;
}
