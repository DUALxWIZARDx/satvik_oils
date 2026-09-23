import 'package:flutter/foundation.dart';

import '../models/sale_history_model.dart';
import '../repositories/sale_repository.dart';

class SaleHistoryProvider extends ChangeNotifier {
  SaleHistoryProvider({SaleRepository? saleRepository})
    : _saleRepository = saleRepository ?? SaleRepository();

  final SaleRepository _saleRepository;

  List<SaleHistoryOrder> _allOrders = const [];
  DateTime _selectedMonth = _initialMonth();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  List<SaleHistoryOrder> get orders {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _allOrders;
    }

    return _allOrders.where((order) {
      final matchesPayment = order.paymentMode.label.toLowerCase().contains(
        query,
      );
      final matchesProduct = order.items.any(
        (item) => item.productName.toLowerCase().contains(query),
      );
      return matchesPayment || matchesProduct;
    }).toList();
  }

  String get searchQuery => _searchQuery;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;

  void setSearchQuery(String value) {
    if (_searchQuery == value) {
      return;
    }

    _searchQuery = value;
    notifyListeners();
  }

  Future<void> selectMonth(DateTime month) async {
    final normalizedMonth = DateTime(month.year, month.month);
    if (normalizedMonth == _selectedMonth && _hasLoaded) {
      return;
    }

    _selectedMonth = normalizedMonth;
    _hasLoaded = false;
    notifyListeners();
    await loadOrders(forceReload: true);
  }

  Future<void> loadOrders({bool forceReload = false}) async {
    if (_isLoading || (_hasLoaded && !forceReload)) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allOrders = await _saleRepository.getSaleHistoryOrders(_selectedMonth);
      _hasLoaded = true;
    } catch (_) {
      _errorMessage = 'Sale history could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes all SQLite rows belonging to [orderKey] and removes the order
  /// from the in-memory list immediately so the UI responds without waiting
  /// for a full reload.
  ///
  /// If the repository call fails the order is restored and [errorMessage]
  /// is set so the screen can surface the problem.
  Future<void> deleteOrder(String orderKey) async {
    // Find and remove the order optimistically.
    final index = _allOrders.indexWhere((o) => o.orderKey == orderKey);
    if (index == -1) return;

    final removed = _allOrders[index];
    _allOrders = List<SaleHistoryOrder>.from(_allOrders)..removeAt(index);
    notifyListeners();

    try {
      await _saleRepository.deleteOrderByKey(orderKey);
    } catch (_) {
      // Restore on failure so the list stays consistent with SQLite.
      final restored = List<SaleHistoryOrder>.from(_allOrders)
        ..insert(index, removed);
      _allOrders = restored;
      _errorMessage = 'Could not delete the order. Please try again.';
      notifyListeners();
    }
  }

  static DateTime _initialMonth() {
    final now = DateTime.now();
    return DateTime(now.year < 2026 ? 2026 : now.year, now.month);
  }
}
