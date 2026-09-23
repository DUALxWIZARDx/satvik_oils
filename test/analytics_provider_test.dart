import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_satvik_oils/models/analytics_model.dart';
import 'package:flutter_application_satvik_oils/models/payment_mode.dart';
import 'package:flutter_application_satvik_oils/repositories/sale_repository.dart';
import 'package:flutter_application_satvik_oils/providers/analytics_provider.dart';

class _FakeSaleRepository extends SaleRepository {
  final requests = <Completer<AnalyticsReport>>[];
  final dateRanges = <(DateTime, DateTime)>[];

  @override
  Future<AnalyticsReport> getAnalytics({
    required DateTime from,
    required DateTime to,
    DateTime? previousFrom,
    DateTime? previousTo,
  }) {
    dateRanges.add((from, to));
    final completer = Completer<AnalyticsReport>();
    requests.add(completer);
    return completer.future;
  }
}

AnalyticsReport reportFor(double revenue, {int orders = 1}) => AnalyticsReport(
  summary: AnalyticsSummary(
    revenue: revenue,
    profit: revenue / 2,
    orders: orders,
  ),
  previous: const AnalyticsSummary(revenue: 0, profit: 0, orders: 0),
  days: const [],
  products: const [],
  payments: const [
    PaymentPerformance(mode: PaymentMode.cash, revenue: 0, orders: 0),
  ],
);

void main() {
  test('keeps Analytics report aligned with the selected month', () async {
    final repository = _FakeSaleRepository();
    final provider = AnalyticsProvider(saleRepository: repository);

    final initialLoad = provider.load();
    final augustLoad = provider.selectMonth(DateTime(2026, 8));

    repository.requests[1].complete(reportFor(800));
    await augustLoad;
    expect(provider.selectedMonth, DateTime(2026, 8));
    expect(provider.report!.summary.revenue, 800);

    repository.requests[0].complete(reportFor(900));
    await initialLoad;
    expect(provider.selectedMonth, DateTime(2026, 8));
    expect(provider.report!.summary.revenue, 800);

    final septemberLoad = provider.selectMonth(DateTime(2026, 9));
    repository.requests[2].complete(reportFor(900));
    await septemberLoad;
    expect(provider.selectedMonth, DateTime(2026, 9));
    expect(provider.report!.summary.revenue, 900);
  });

  test(
    'replaces sales with zero values when the selected month has no sales',
    () async {
      final repository = _FakeSaleRepository();
      final provider = AnalyticsProvider(saleRepository: repository);

      final septemberLoad = provider.selectMonth(DateTime(2026, 9));
      repository.requests[0].complete(reportFor(900));
      await septemberLoad;
      expect(provider.report!.summary.revenue, 900);

      final augustLoad = provider.selectMonth(DateTime(2026, 8));
      expect(provider.report, isNull);
      expect(repository.dateRanges[1].$1, DateTime(2026, 8, 1));
      expect(repository.dateRanges[1].$2, DateTime(2026, 8, 31));
      repository.requests[1].complete(reportFor(0, orders: 0));
      await augustLoad;
      expect(provider.report!.summary.revenue, 0);
      expect(provider.report!.summary.profit, 0);
      expect(provider.report!.summary.orders, 0);
      expect(provider.report!.summary.aov, 0);

      final septemberAgain = provider.selectMonth(DateTime(2026, 9));
      repository.requests[2].complete(reportFor(900));
      await septemberAgain;
      expect(provider.report!.summary.revenue, 900);
    },
  );

  test(
    'filters quarterly and annual selections to their calendar periods',
    () async {
      final repository = _FakeSaleRepository();
      final provider = AnalyticsProvider(saleRepository: repository);

      final quarterLoad = provider.selectQuarter(3, 2026);
      repository.requests.single.complete(reportFor(300));
      await quarterLoad;
      expect(provider.periodLabel, 'Q3 2026');
      expect(repository.dateRanges.single, (
        DateTime(2026, 7),
        DateTime(2026, 9, 30),
      ));

      final annualLoad = provider.selectYear(2026);
      repository.requests[1].complete(reportFor(600));
      await annualLoad;
      expect(provider.periodLabel, '2026');
      expect(repository.dateRanges[1], (
        DateTime(2026),
        DateTime(2026, 12, 31),
      ));
    },
  );

  test(
    'switching modes clears the previous period report before loading',
    () async {
      final repository = _FakeSaleRepository();
      final provider = AnalyticsProvider(saleRepository: repository);

      final monthlyLoad = provider.selectMonth(DateTime(2026, 8));
      repository.requests.single.complete(reportFor(800));
      await monthlyLoad;

      final quarterlyLoad = provider.selectQuarter(3, 2026);
      expect(provider.report, isNull);
      repository.requests[1].complete(reportFor(900));
      await quarterlyLoad;

      final annualLoad = provider.selectYear(2026);
      expect(provider.report, isNull);
      repository.requests[2].complete(reportFor(1200));
      await annualLoad;
      expect(provider.report!.summary.revenue, 1200);
    },
  );
}
