import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../core/constants/product_catalog.dart';
import '../models/analytics_model.dart';
import '../repositories/sale_repository.dart';

enum AnalyticsMode { monthly, quarterly, annual }

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider({SaleRepository? saleRepository})
    : _saleRepository = saleRepository ?? SaleRepository();

  final SaleRepository _saleRepository;
  AnalyticsMode _mode = AnalyticsMode.monthly;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;
  int _selectedYear = DateTime.now().year;
  AnalyticsReport? _report;
  bool _isLoading = false;
  String? _error;
  int _loadRequest = 0;

  AnalyticsMode get mode => _mode;
  DateTime get selectedMonth => _selectedMonth;
  int get selectedQuarter => _selectedQuarter;
  int get selectedYear => _selectedYear;
  AnalyticsReport? get report => _report;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get periodLabel {
    switch (_mode) {
      case AnalyticsMode.monthly:
        return '${DateFormat('MMMM').format(_selectedMonth)} $_selectedYear';
      case AnalyticsMode.quarterly:
        return 'Q$_selectedQuarter $_selectedYear';
      case AnalyticsMode.annual:
        return '$_selectedYear';
    }
  }

  String get periodTableLabel {
    switch (_mode) {
      case AnalyticsMode.monthly:
        return DateFormat('MMM').format(_selectedMonth).toUpperCase();
      case AnalyticsMode.quarterly:
        return 'Q$_selectedQuarter';
      case AnalyticsMode.annual:
        return '$_selectedYear';
    }
  }

  Future<void> load() async {
    final request = ++_loadRequest;
    final dates = _periodDates;
    _isLoading = true;
    notifyListeners();
    try {
      final report = await _saleRepository.getAnalytics(
        from: dates.$1,
        to: dates.$2,
      );
      if (request == _loadRequest) {
        _report = report;
        _error = null;
      }
    } catch (_) {
      if (request == _loadRequest) {
        _error = 'Analytics data could not be loaded.';
      }
    } finally {
      if (request == _loadRequest) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectMonth(DateTime month) async {
    _mode = AnalyticsMode.monthly;
    _selectedMonth = DateTime(month.year, month.month);
    _selectedYear = month.year;
    await _reload();
  }

  Future<void> selectQuarter(int quarter, int year) async {
    _mode = AnalyticsMode.quarterly;
    _selectedQuarter = quarter;
    _selectedYear = year;
    await _reload();
  }

  Future<void> selectYear(int year) async {
    _mode = AnalyticsMode.annual;
    _selectedYear = year;
    await _reload();
  }

  Future<void> selectMode(AnalyticsMode mode) async {
    _mode = mode;
    await _reload();
  }

  Future<void> _reload() async {
    // Clear the stale report and error, flag loading, then notify the UI so
    // widgets never see a new period paired with the old period's data.
    _report = null;
    _error = null;
    _isLoading = true;
    notifyListeners();
    await load();
  }

  (DateTime, DateTime) get _periodDates {
    switch (_mode) {
      case AnalyticsMode.monthly:
        return (
          DateTime(_selectedMonth.year, _selectedMonth.month),
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
        );
      case AnalyticsMode.quarterly:
        final startMonth = (_selectedQuarter - 1) * 3 + 1;
        return (
          DateTime(_selectedYear, startMonth),
          DateTime(_selectedYear, startMonth + 3, 0),
        );
      case AnalyticsMode.annual:
        return (DateTime(_selectedYear), DateTime(_selectedYear, 12, 31));
    }
  }

  ProductPerformance performanceFor(CatalogProduct product) {
    final reportProduct = _report?.products.where(
      (item) => item.productId == product.id,
    );
    if (reportProduct != null && reportProduct.isNotEmpty) {
      return reportProduct.first;
    }

    return ProductPerformance(
      productId: product.id,
      name: product.name,
      quantity: 0,
      revenue: 0,
      profit: 0,
      litresSold: 0,
      variants: [
        for (final variant in product.quantityVariants)
          VariantPerformance(
            variant: variant,
            quantity: 0,
            revenue: 0,
            profit: 0,
          ),
      ],
    );
  }
}
