class DbSchema {
  const DbSchema._();
  static const int version = 3;
}

class ProductTable {
  const ProductTable._();

  static const String tableName = 'products';

  static const String id = 'id';
  static const String name = 'name';
  static const String isActive = 'is_active';
}

class ProductPriceTable {
  const ProductPriceTable._();

  static const String tableName = 'product_prices';

  static const String id = 'id';
  static const String productId = 'product_id';
  static const String quantityVariant = 'quantity_variant';
  static const String sellingPrice = 'selling_price';
  static const String costPrice = 'cost_price';
  static const String effectiveFrom = 'effective_from';
}

class CustomerTable {
  const CustomerTable._();

  static const String tableName = 'customers';

  static const String id = 'id';
  static const String name = 'name';
  static const String phone = 'phone';
  static const String address = 'address';
  static const String createdAt = 'created_at';
}

class SaleTable {
  const SaleTable._();

  static const String tableName = 'sales';

  static const String id = 'id';
  static const String createdAt = 'created_at';
  static const String saleDate = 'sale_date';
  static const String saleTime = 'sale_time';
  static const String productId = 'product_id';
  static const String productNameSnapshot = 'product_name_snapshot';
  static const String quantityVariant = 'quantity_variant';
  static const String unitPriceSnapshot = 'unit_price_snapshot';
  static const String costPriceSnapshot = 'cost_price_snapshot';
  static const String discountType = 'discount_type';
  static const String discountValue = 'discount_value';
  static const String totalAmount = 'total_amount';
  static const String paymentMode = 'payment_mode';
  static const String customerId = 'customer_id';
  static const String syncedAt = 'synced_at';
  static const String orderId = 'order_id';
  static const String orderSubtotal = 'order_subtotal';
  static const String orderDiscountPercent = 'order_discount_percent';
  static const String orderDiscountAmount = 'order_discount_amount';
  static const String orderFinalTotal = 'order_final_total';
}

class AppSettingsTable {
  const AppSettingsTable._();

  static const String tableName = 'app_settings';

  static const String key = 'key';
  static const String value = 'value';
  static const String updatedAt = 'updated_at';
}
