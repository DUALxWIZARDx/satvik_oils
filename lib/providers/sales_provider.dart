import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/product_catalog.dart';
import '../models/payment_mode.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';
import '../models/discount_type.dart';
import '../models/cart_item.dart';

class SalesProvider extends ChangeNotifier {
  SalesProvider({ProductRepository? productRepository, SaleRepository? saleRepository})
      : _productRepository = productRepository ?? ProductRepository(),
        _saleRepository = saleRepository ?? SaleRepository();

  final ProductRepository _productRepository;
  final SaleRepository _saleRepository;

  CatalogProduct? selectedProduct = ProductCatalog.products.first;
  String selectedVariant = ProductCatalog.quantityVariants.first;
  int quantity = 1;
  PaymentMode selectedPaymentMode = PaymentMode.cash;

  bool _isSaving = false;
  String? _error;

  bool get isSaving => _isSaving;
  String? get error => _error;

  CurrentProductPrice? _currentPrice;

  CurrentProductPrice? get currentPrice => _currentPrice;

  final List<CartItem> _cart = [];
  List<CartItem> get cart => List.unmodifiable(_cart);

  int _orderDiscountPercent = 0; // 0 means no discount

  int get orderDiscountPercent => _orderDiscountPercent;

  void setOrderDiscountPercent(int percent) {
    _orderDiscountPercent = percent.clamp(0, 100);
    notifyListeners();
  }

  final Uuid _uuid = const Uuid();

  double get cartTotal => _cart.fold(0.0, (s, it) => s + it.lineTotal);

  double get subtotal => cartTotal;

  double get discountAmount => (subtotal * _orderDiscountPercent / 100.0);

  double get finalTotal => (subtotal - discountAmount).clamp(0, double.infinity).toDouble();

  Future<void> refreshCurrentPrice() async {
    final product = selectedProduct;
    if (product == null) return;

    final priceDetails = await _productRepository.getCurrentPriceDetails(
      productId: product.id,
      quantityVariant: selectedVariant,
    );

    _currentPrice = priceDetails;
    notifyListeners();
  }

  void selectProduct(CatalogProduct product) {
    selectedProduct = product;
    selectedVariant = product.quantityVariants.first;
    _currentPrice = null;
    notifyListeners();
  }

  void selectVariant(String variant) {
    selectedVariant = variant;
    _currentPrice = null;
    notifyListeners();
  }

  void setQuantity(int q) {
    quantity = q.clamp(1, 1000000);
    notifyListeners();
  }

  /// Add currently selected product/variant to the in-memory cart.
  /// Captures the current selling price snapshot.
  Future<void> addToCart() async {
    final product = selectedProduct;
    if (product == null) {
      _error = 'Select product';
      notifyListeners();
      return;
    }

    // ensure current price is loaded
    if (_currentPrice == null) {
      await refreshCurrentPrice();
    }

    if (_currentPrice == null) {
      _error = 'Price not available';
      notifyListeners();
      return;
    }

    // find existing cart item for same product+variant
    final existingIndex = _cart.indexWhere((c) => c.productId == product.id && c.variant == selectedVariant);
    if (existingIndex >= 0) {
      _cart[existingIndex].quantity += quantity;
    } else {
      _cart.add(CartItem(
        productId: product.id,
        productName: product.name,
        variant: selectedVariant,
        quantity: quantity,
        unitPriceSnapshot: _currentPrice!.sellingPrice,
        costPriceSnapshot: _currentPrice!.costPrice,
      ));
    }

    _error = null;
    notifyListeners();
  }

  void removeCartItem(CartItem item) {
    _cart.remove(item);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<void> saveOrder({String? customerId}) async {
    if (_cart.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    final orderId = _uuid.v4();

    final orderSubtotal = subtotal;
    final orderDiscountPercent = _orderDiscountPercent;
    final orderDiscountAmount = discountAmount;
    final orderFinalTotal = finalTotal;

    try {
      for (final item in List<CartItem>.from(_cart)) {
        final sale = _saleRepository.buildNewSale(
          productId: item.productId,
          productNameSnapshot: item.productName,
          quantityVariant: item.variant,
          unitPriceSnapshot: item.unitPriceSnapshot,
          costPriceSnapshot: item.costPriceSnapshot,
          discountType: DiscountType.none,
          discountValue: 0,
          totalAmount: item.lineTotal,
          paymentMode: selectedPaymentMode,
          customerId: customerId,
          orderId: orderId,
          orderSubtotal: orderSubtotal,
          orderDiscountPercent: orderDiscountPercent,
          orderDiscountAmount: orderDiscountAmount,
          orderFinalTotal: orderFinalTotal,
        );

        await _saleRepository.insertSale(sale);
      }

      // clear cart after successful save
      clearCart();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  double get unitSellingPrice => _currentPrice?.sellingPrice ?? 0.0;
  double get unitCostPrice => _currentPrice?.costPrice ?? 0.0;

  double get totalRevenue => unitSellingPrice * quantity;
  double get totalCost => unitCostPrice * quantity;
  double get profit => totalRevenue - totalCost;

  Future<void> saveSale({String? customerId}) async {
    final product = selectedProduct;
    if (product == null || _currentPrice == null) {
      _error = 'Select product and variant';
      notifyListeners();
      return;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final sale = _saleRepository.buildNewSale(
        productId: product.id,
        productNameSnapshot: product.name,
        quantityVariant: selectedVariant,
        unitPriceSnapshot: _currentPrice!.sellingPrice,
        costPriceSnapshot: _currentPrice!.costPrice,
        discountType: DiscountType.none,
        discountValue: 0,
        totalAmount: totalRevenue,
        paymentMode: selectedPaymentMode,
        customerId: customerId,
      );

      await _saleRepository.insertSale(sale);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void setPaymentMode(PaymentMode mode) {
    selectedPaymentMode = mode;
    notifyListeners();
  }

  double get todaysSalesRevenue => 0;

  int get todaysOrdersCount => 0;
}
