import '../models/discount_type.dart';

class PricingResult {
  const PricingResult({
    required this.unitPrice,
    required this.costPrice,
    required this.discountValue,
    required this.totalAmount,
  });

  final double unitPrice;
  final double costPrice;
  final double discountValue;
  final double totalAmount;
}

class PricingService {
  const PricingService();

  PricingResult calculateSalePrice({
    required double unitPrice,
    required double costPrice,
    required DiscountType discountType,
    double customDiscountValue = 0,
  }) {
    final discountValue = resolveDiscountValue(
      unitPrice: unitPrice,
      discountType: discountType,
      customDiscountValue: customDiscountValue,
    );

    return PricingResult(
      unitPrice: unitPrice,
      costPrice: costPrice,
      discountValue: discountValue,
      totalAmount: (unitPrice - discountValue)
          .clamp(0, double.infinity)
          .toDouble(),
    );
  }

  double resolveDiscountValue({
    required double unitPrice,
    required DiscountType discountType,
    double customDiscountValue = 0,
  }) {
    final percent = discountType.percent;
    if (percent != null) {
      return unitPrice * percent / 100;
    }

    if (discountType == DiscountType.custom) {
      return customDiscountValue.clamp(0, unitPrice).toDouble();
    }

    return 0;
  }
}
