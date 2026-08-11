import 'package:flutter/foundation.dart';

import '../core/constants/product_catalog.dart';
import '../repositories/product_repository.dart';

class ProductsPricingProvider extends ChangeNotifier {
  ProductsPricingProvider({ProductRepository? productRepository})
    : _productRepository = productRepository ?? ProductRepository();

  final ProductRepository _productRepository;
  final Map<String, List<CurrentProductPrice>> _currentPricesByProductId = {};

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<CurrentProductPrice> currentPricesFor(String productId) {
    return _currentPricesByProductId[productId] ?? const [];
  }

  Future<void> loadCurrentPrices(
    List<CatalogProduct> products, {
    bool forceReload = false,
  }) async {
    if (_isLoading || (_hasLoaded && !forceReload)) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedPrices = <String, List<CurrentProductPrice>>{};

      for (final product in products) {
        loadedPrices[product.id] = await _productRepository.getCurrentPrices(
          productId: product.id,
        );
      }

      _currentPricesByProductId
        ..clear()
        ..addAll(loadedPrices);
      _hasLoaded = true;
    } catch (_) {
      _errorMessage = 'Pricing data could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProductPrice({
    required String productId,
    required String quantityVariant,
    required double sellingPrice,
    required double costPrice,
    String? note,
  }) async {
    if (quantityVariant == '1L') {
      await _productRepository.saveBaseCostAndPropagate(
        productId: productId,
        baseCostPrice1L: costPrice,
        sellingPriceFor1L: sellingPrice,
      );
    } else {
      // Non-1L: costPrice should be calculated from 1L and provided by UI as read-only.
      await _productRepository.savePrice(
        productId: productId,
        quantityVariant: quantityVariant,
        sellingPrice: sellingPrice,
        costPrice: costPrice,
      );
    }

    await loadCurrentPrices(
      ProductCatalog.products,
      forceReload: true,
    );
  }
}
