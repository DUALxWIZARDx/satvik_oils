import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_satvik_oils/models/discount_type.dart';
import 'package:flutter_application_satvik_oils/models/payment_mode.dart';
import 'package:flutter_application_satvik_oils/models/sale_model.dart';
import 'package:flutter_application_satvik_oils/repositories/sale_repository.dart';

SaleModel sale({
  required String id,
  required String order,
  required String product,
  required String variant,
  required double total,
  required double finalTotal,
  required double cost,
  PaymentMode mode = PaymentMode.cash,
}) => SaleModel(
  id: id,
  createdAt: DateTime(2026, 6, 1),
  saleDate: '2026-06-01',
  saleTime: '10:00:00',
  productId: product,
  productNameSnapshot: product,
  quantityVariant: variant,
  unitPriceSnapshot: 100,
  costPriceSnapshot: cost,
  discountType: DiscountType.none,
  discountValue: 0,
  totalAmount: total,
  paymentMode: mode,
  orderId: order,
  orderFinalTotal: finalTotal,
);

void main() {
  test(
    'groups multi-line orders and allocates order discount proportionally',
    () {
      final report = SaleRepository.buildAnalytics([
        sale(
          id: 'a',
          order: 'one',
          product: 'Groundnut',
          variant: '1L',
          total: 600,
          finalTotal: 900,
          cost: 40,
        ),
        sale(
          id: 'b',
          order: 'one',
          product: 'Coconut',
          variant: '1L',
          total: 400,
          finalTotal: 900,
          cost: 50,
        ),
      ], []);
      expect(report.summary.orders, 1);
      expect(report.summary.revenue, 900);
      expect(report.summary.profit, 460);
      expect(
        report.products.firstWhere((p) => p.name == 'Groundnut').revenue,
        540,
      );
      expect(
        report.products.firstWhere((p) => p.name == 'Coconut').revenue,
        360,
      );
    },
  );
  test('keeps payment orders unique', () {
    final report = SaleRepository.buildAnalytics([
      sale(
        id: 'a',
        order: 'one',
        product: 'Groundnut',
        variant: '1L',
        total: 100,
        finalTotal: 100,
        cost: 20,
        mode: PaymentMode.upi,
      ),
      sale(
        id: 'b',
        order: 'one',
        product: 'Coconut',
        variant: '1L',
        total: 100,
        finalTotal: 100,
        cost: 20,
        mode: PaymentMode.upi,
      ),
    ], []);
    final upi = report.payments.firstWhere((p) => p.mode == PaymentMode.upi);
    expect(upi.orders, 1);
    expect(upi.revenue, 100);
  });

  test('keeps variant quantities and calculates litres', () {
    final report = SaleRepository.buildAnalytics([
      sale(
        id: 'a',
        order: 'one',
        product: 'groundnut_oil',
        variant: '1L',
        total: 200,
        finalTotal: 200,
        cost: 40,
      ).copyWith(unitPriceSnapshot: 100),
      sale(
        id: 'b',
        order: 'two',
        product: 'groundnut_oil',
        variant: '500ml',
        total: 300,
        finalTotal: 300,
        cost: 40,
      ).copyWith(unitPriceSnapshot: 100),
      sale(
        id: 'c',
        order: 'three',
        product: 'groundnut_oil',
        variant: '250ml',
        total: 400,
        finalTotal: 400,
        cost: 40,
      ).copyWith(unitPriceSnapshot: 100),
      sale(
        id: 'd',
        order: 'four',
        product: 'groundnut_oil',
        variant: '2L',
        total: 360,
        finalTotal: 324,
        cost: 80,
      ).copyWith(unitPriceSnapshot: 180),
    ], []);

    final product = report.products.single;
    expect(product.variants.firstWhere((v) => v.variant == '1L').quantity, 2);
    expect(
      product.variants.firstWhere((v) => v.variant == '500ml').quantity,
      3,
    );
    expect(
      product.variants.firstWhere((v) => v.variant == '250ml').quantity,
      4,
    );
    final twoL = product.variants.firstWhere((v) => v.variant == '2L');
    expect(twoL.quantity, 2);
    expect(twoL.revenue, 324);
    expect(twoL.profit, 164);
    expect(product.litresSold, 8.5);
  });
}
