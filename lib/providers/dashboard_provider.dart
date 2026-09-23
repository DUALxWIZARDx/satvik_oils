import 'package:flutter/foundation.dart';

import '../core/utils/date_time_service.dart';
import '../models/dashboard_model.dart';
import '../repositories/sale_repository.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    SaleRepository? saleRepository,
    DateTimeService? dateTimeService,
  })  : _saleRepository = saleRepository ?? SaleRepository(),
      _dateTimeService = dateTimeService ?? DateTimeService(),
      _ownsDateTimeService = dateTimeService == null {
    _dateTimeService.addListener(_handleDateChanged);
  }

  final SaleRepository _saleRepository;
  final DateTimeService _dateTimeService;
  final bool _ownsDateTimeService;

  DashboardSummary? _summary;
  List<TopSellingOilToday> _topSellingOils = const [];
  List<RecentOrderSummary> _recentOrders = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  DashboardSummary? get summary => _summary;
  List<TopSellingOilToday> get topSellingOils => _topSellingOils;
  List<RecentOrderSummary> get recentOrders => _recentOrders;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  bool get hasOrdersToday => _summary?.hasOrders ?? false;

  Future<void> loadToday({bool forceReload = false}) async {
    if (_isLoading || (_hasLoaded && !forceReload)) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final today = _dateTimeService.today;
      final summary = await _saleRepository.getDashboardSummaryForDate(today);
      final topSellingOils = await _saleRepository.getTopSellingOilsForDate(
        today,
      );
      final recentOrders = await _saleRepository.getRecentOrdersForDate(today);

      _summary = summary;
      _topSellingOils = topSellingOils;
      _recentOrders = recentOrders;
      _hasLoaded = true;
    } catch (_) {
      _errorMessage = 'Dashboard data could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleDateChanged() {
    _hasLoaded = false;
    loadToday(forceReload: true);
  }

  @override
  void dispose() {
    _dateTimeService.removeListener(_handleDateChanged);
    if (_ownsDateTimeService) {
      _dateTimeService.dispose();
    }
    super.dispose();
  }
}
