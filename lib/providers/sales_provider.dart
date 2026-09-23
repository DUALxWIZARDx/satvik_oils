import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/product_catalog.dart';
import '../core/utils/date_time_service.dart';
import '../models/payment_mode.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';
import '../models/discount_type.dart';
import '../models/cart_item.dart';
import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';

class SalesProvider extends ChangeNotifier {
  SalesProvider({
    ProductRepository? productRepository,
    SaleRepository? saleRepository,
    DateTimeService? dateTimeService,
    CustomerRepository? customerRepository,
  }) : _productRepository = productRepository ?? ProductRepository(),
       _saleRepository = saleRepository ?? SaleRepository(),
       _dateTimeService = dateTimeService ?? DateTimeService(),
       _customerRepository = customerRepository ?? CustomerRepository(),
       _ownsDateTimeService = dateTimeService == null;

  final ProductRepository _productRepository;
  final SaleRepository _saleRepository;
  final DateTimeService _dateTimeService;
  final bool _ownsDateTimeService;
  final CustomerRepository _customerRepository;

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
  CustomerModel? _selectedCustomer;
  CustomerModel? get selectedCustomer => _selectedCustomer;
  bool get hasMembershipDiscount => _selectedCustomer?.isMembership ?? false;
  int get effectiveDiscountPercent =>
      hasMembershipDiscount ? 5 : _orderDiscountPercent;

  String? _editingOrderKey;
  DateTime? _editingOrderCreatedAt;
  String? _editingCustomerId;

  bool get isEditingOrder => _editingOrderKey != null;
  String? get editingOrderKey => _editingOrderKey;

  void selectCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    if (isEditingOrder) {
      _editingCustomerId = customer?.id;
    }
    notifyListeners();
  }

  void syncMembershipCustomers(List<CustomerModel> customers) {
    final selectedCustomer = _selectedCustomer;
    if (selectedCustomer == null ||
        customers.any((customer) => customer.id == selectedCustomer.id)) {
      return;
    }

    _selectedCustomer = null;
    notifyListeners();
  }

  void setOrderDiscountPercent(int percent) {
    _orderDiscountPercent = percent.clamp(0, 100);
    notifyListeners();
  }

  final Uuid _uuid = const Uuid();

  double get cartTotal => _cart.fold(0.0, (s, it) => s + it.lineTotal);

  double get subtotal => cartTotal;

  double get discountAmount => (subtotal * effectiveDiscountPercent / 100.0);

  double get finalTotal =>
      (subtotal - discountAmount).clamp(0, double.infinity).toDouble();

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
    final existingIndex = _cart.indexWhere(
      (c) => c.productId == product.id && c.variant == selectedVariant,
    );
    if (existingIndex >= 0) {
      _cart[existingIndex].quantity += quantity;
    } else {
      _cart.add(
        CartItem(
          productId: product.id,
          productName: product.name,
          variant: selectedVariant,
          quantity: quantity,
          unitPriceSnapshot: _currentPrice!.sellingPrice,
          costPriceSnapshot: _currentPrice!.costPrice,
        ),
      );
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

  /// Loads a saved logical order into the existing sales cart.  Price and
  /// cost snapshots come from the saved rows, not today's price list.
  Future<void> beginEditOrder(String orderKey) async {
    _error = null;
    notifyListeners();

    try {
      final lines = await _saleRepository.getOrderByKey(orderKey);
      if (lines.isEmpty) {
        throw StateError('Order no longer exists.');
      }

      final first = lines.first;
      final customerId = first.customerId;
      _cart
        ..clear()
        ..addAll(
          lines.map(
            (line) => CartItem(
              productId: line.productId,
              productName: line.productNameSnapshot,
              variant: line.quantityVariant,
              quantity: line.unitPriceSnapshot == 0
                  ? 1
                  : (line.totalAmount / line.unitPriceSnapshot).round(),
              unitPriceSnapshot: line.unitPriceSnapshot,
              costPriceSnapshot: line.costPriceSnapshot,
            ),
          ),
        );
      _editingOrderKey = orderKey;
      _editingOrderCreatedAt = first.createdAt;
      _editingCustomerId = customerId;
      _selectedCustomer = customerId == null
          ? null
          : await _customerRepository.getCustomerById(customerId);
      _orderDiscountPercent = first.orderDiscountPercent ?? 0;
      selectedPaymentMode = first.paymentMode;
      quantity = 1;
      _currentPrice = null;
    } catch (e) {
      _error = e.toString();
    }
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

    final isEditing = isEditingOrder;
    final orderId = _editingOrderKey ?? _uuid.v4();
    // An edit must retain the instant originally stored for this order.
    final saleTimestamp =
        _editingOrderCreatedAt ?? _dateTimeService.currentDateTime;

    final orderSubtotal = subtotal;
    final selectedCustomer = _selectedCustomer;
    final isMembership = selectedCustomer?.isMembership ?? false;
    final orderDiscountPercent = isMembership ? 5 : _orderDiscountPercent;
    final orderDiscountAmount = orderSubtotal * orderDiscountPercent / 100.0;
    final orderFinalTotal = (orderSubtotal - orderDiscountAmount)
        .clamp(0, double.infinity)
        .toDouble();

    try {
      final orderLines = List<CartItem>.from(_cart).map((item) {
        return _saleRepository.buildNewSale(
          productId: item.productId,
          productNameSnapshot: item.productName,
          quantityVariant: item.variant,
          unitPriceSnapshot: item.unitPriceSnapshot,
          costPriceSnapshot: item.costPriceSnapshot,
          discountType: DiscountType.none,
          discountValue: 0,
          totalAmount: item.lineTotal,
          paymentMode: selectedPaymentMode,
          customerId: customerId ?? selectedCustomer?.id ?? _editingCustomerId,
          orderId: orderId,
          createdAt: saleTimestamp,
          orderSubtotal: orderSubtotal,
          orderDiscountPercent: orderDiscountPercent,
          orderDiscountAmount: orderDiscountAmount,
          orderFinalTotal: orderFinalTotal,
          orderDiscountSource: isMembership
              ? 'membership'
              : (orderDiscountPercent > 0 ? 'manual' : null),
        );
      }).toList();

      if (isEditing) {
        await _saleRepository.updateOrderByKey(
          orderKey: orderId,
          originalCreatedAt: saleTimestamp,
          updatedLines: orderLines,
        );
      } else {
        for (final line in orderLines) {
          await _saleRepository.insertSale(line);
        }
      }

      // clear cart after successful save
      _cart.clear();
      _editingOrderKey = null;
      _editingOrderCreatedAt = null;
      _editingCustomerId = null;
      _selectedCustomer = null;
      _orderDiscountPercent = 0;
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
      final saleTimestamp = _dateTimeService.currentDateTime;
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
        createdAt: saleTimestamp,
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

  @override
  void dispose() {
    if (_ownsDateTimeService) {
      _dateTimeService.dispose();
    }
    super.dispose();
  }
}
