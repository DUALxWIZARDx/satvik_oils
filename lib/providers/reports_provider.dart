import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import '../models/analytics_model.dart';
import '../repositories/sale_repository.dart';

enum AnalyticsPeriod { month, year, custom }

class ReportsProvider extends ChangeNotifier {
  ReportsProvider({SaleRepository? saleRepository})
    : _sales = saleRepository ?? SaleRepository();
  final SaleRepository _sales;
  AnalyticsPeriod _period = AnalyticsPeriod.month;
  DateTime _anchor = DateTime.now();
  DateTimeRange? _range;
  AnalyticsReport? _report;
  bool _loading = false;
  String? _error;
  AnalyticsPeriod get period => _period;
  DateTime get anchor => _anchor;
  DateTimeRange? get range => _range;
  AnalyticsReport? get report => _report;
  bool get isLoading => _loading;
  String? get error => _error;
  Future<void> setPeriod(
    AnalyticsPeriod value, {
    DateTime? anchor,
    DateTimeRange? range,
  }) async {
    _period = value;
    _anchor = anchor ?? _anchor;
    _range = range ?? _range;
    await load();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final dates = _dates();
      _report = await _sales.getAnalytics(
        from: dates.$1,
        to: dates.$2,
        previousFrom: dates.$3,
        previousTo: dates.$4,
      );
      _error = null;
    } catch (e) {
      _error = 'Analytics data could not be loaded.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  (DateTime, DateTime, DateTime, DateTime) _dates() {
    DateTime from, to;
    if (_period == AnalyticsPeriod.custom && _range != null) {
      from = _range!.start;
      to = _range!.end;
    } else if (_period == AnalyticsPeriod.year) {
      from = DateTime(_anchor.year);
      to = DateTime(_anchor.year, 12, 31);
    } else {
      from = DateTime(_anchor.year, _anchor.month);
      to = DateTime(_anchor.year, _anchor.month + 1, 0);
    }
    final length = to.difference(from).inDays + 1;
    final previousTo = from.subtract(const Duration(days: 1));
    return (
      from,
      to,
      previousTo.subtract(Duration(days: length - 1)),
      previousTo,
    );
  }
}
