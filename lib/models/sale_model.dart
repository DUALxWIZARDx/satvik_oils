import '../core/database/db_schema.dart';
import 'discount_type.dart';
import 'payment_mode.dart';

class SaleModel {
  const SaleModel({
    required this.id,
    required this.createdAt,
    required this.saleDate,
    required this.saleTime,
    required this.productId,
    required this.productNameSnapshot,
    required this.quantityVariant,
    required this.unitPriceSnapshot,
    required this.costPriceSnapshot,
    required this.discountType,
    required this.discountValue,
    required this.totalAmount,
    required this.paymentMode,
    this.orderId,
    this.customerId,
    this.syncedAt,
  });

  final String id;
  final DateTime createdAt;
  final String saleDate;
  final String saleTime;
  final String productId;
  final String productNameSnapshot;
  final String quantityVariant;
  final double unitPriceSnapshot;
  final double costPriceSnapshot;
  final DiscountType discountType;
  final double discountValue;
  final double totalAmount;
  final PaymentMode paymentMode;
  final String? orderId;
  final String? customerId;
  final DateTime? syncedAt;

  factory SaleModel.fromMap(Map<String, Object?> map) {
    return SaleModel(
      id: map[SaleTable.id] as String,
      createdAt: DateTime.parse(map[SaleTable.createdAt] as String),
      saleDate: map[SaleTable.saleDate] as String,
      saleTime: map[SaleTable.saleTime] as String,
      productId: map[SaleTable.productId] as String,
      productNameSnapshot: map[SaleTable.productNameSnapshot] as String,
      quantityVariant: map[SaleTable.quantityVariant] as String,
      unitPriceSnapshot: (map[SaleTable.unitPriceSnapshot] as num).toDouble(),
      costPriceSnapshot: (map[SaleTable.costPriceSnapshot] as num).toDouble(),
      discountType: DiscountType.fromDbValue(
        map[SaleTable.discountType] as String,
      ),
      discountValue: (map[SaleTable.discountValue] as num).toDouble(),
      totalAmount: (map[SaleTable.totalAmount] as num).toDouble(),
      paymentMode: PaymentMode.fromDbValue(
        map[SaleTable.paymentMode] as String,
      ),
      orderId: map[SaleTable.orderId] as String?,
      customerId: map[SaleTable.customerId] as String?,
      syncedAt: map[SaleTable.syncedAt] == null
          ? null
          : DateTime.parse(map[SaleTable.syncedAt] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      SaleTable.id: id,
      SaleTable.createdAt: createdAt.toIso8601String(),
      SaleTable.saleDate: saleDate,
      SaleTable.saleTime: saleTime,
      SaleTable.productId: productId,
      SaleTable.productNameSnapshot: productNameSnapshot,
      SaleTable.quantityVariant: quantityVariant,
      SaleTable.unitPriceSnapshot: unitPriceSnapshot,
      SaleTable.costPriceSnapshot: costPriceSnapshot,
      SaleTable.discountType: discountType.dbValue,
      SaleTable.discountValue: discountValue,
      SaleTable.totalAmount: totalAmount,
      SaleTable.paymentMode: paymentMode.dbValue,
      SaleTable.orderId: orderId,
      SaleTable.customerId: customerId,
      SaleTable.syncedAt: syncedAt?.toIso8601String(),
    };
  }

  SaleModel copyWith({
    String? id,
    DateTime? createdAt,
    String? saleDate,
    String? saleTime,
    String? productId,
    String? productNameSnapshot,
    String? quantityVariant,
    double? unitPriceSnapshot,
    double? costPriceSnapshot,
    DiscountType? discountType,
    double? discountValue,
    double? totalAmount,
    PaymentMode? paymentMode,
    String? orderId,
    String? customerId,
    DateTime? syncedAt,
  }) {
    return SaleModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      saleDate: saleDate ?? this.saleDate,
      saleTime: saleTime ?? this.saleTime,
      productId: productId ?? this.productId,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      quantityVariant: quantityVariant ?? this.quantityVariant,
      unitPriceSnapshot: unitPriceSnapshot ?? this.unitPriceSnapshot,
      costPriceSnapshot: costPriceSnapshot ?? this.costPriceSnapshot,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
}
