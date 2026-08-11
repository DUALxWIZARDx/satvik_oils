import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../core/database/db_helper.dart';
import '../core/database/db_schema.dart';
import '../models/discount_type.dart';
import '../models/payment_mode.dart';
import '../models/sale_model.dart';

class SaleRepository {
  SaleRepository({DbHelper? dbHelper, Uuid? uuid})
    : _dbHelper = dbHelper ?? DbHelper.instance,
      _uuid = uuid ?? const Uuid();

  static final DateFormat _saleDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _saleTimeFormat = DateFormat('HH:mm:ss');

  final DbHelper _dbHelper;
  final Uuid _uuid;

  SaleModel buildNewSale({
    required String productId,
    required String productNameSnapshot,
    required String quantityVariant,
    required double unitPriceSnapshot,
    required double costPriceSnapshot,
    required DiscountType discountType,
    required double discountValue,
    required double totalAmount,
    required PaymentMode paymentMode,
    String? customerId,
    String? orderId,
    DateTime? createdAt,
  }) {
    final saleCreatedAt = createdAt ?? DateTime.now();

    return SaleModel(
      id: _uuid.v4(),
      createdAt: saleCreatedAt,
      saleDate: _saleDateFormat.format(saleCreatedAt),
      saleTime: _saleTimeFormat.format(saleCreatedAt),
      productId: productId,
      productNameSnapshot: productNameSnapshot,
      quantityVariant: quantityVariant,
      unitPriceSnapshot: unitPriceSnapshot,
      costPriceSnapshot: costPriceSnapshot,
      discountType: discountType,
      discountValue: discountValue,
      totalAmount: totalAmount,
      paymentMode: paymentMode,
      orderId: orderId,
      customerId: customerId,
    );
  }

  Future<void> insertSale(SaleModel sale) async {
    final db = await _dbHelper.database;
    await db.insert(SaleTable.tableName, sale.toMap());
  }

  Future<SaleModel?> getSaleById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      SaleTable.tableName,
      where: '${SaleTable.id} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return SaleModel.fromMap(rows.first);
  }

  Future<List<SaleModel>> getSales({
    String? saleDate,
    DateTime? fromDate,
    DateTime? toDate,
    String? productId,
    String? customerId,
    PaymentMode? paymentMode,
  }) async {
    final db = await _dbHelper.database;
    final whereParts = <String>[];
    final whereArgs = <Object?>[];

    if (saleDate != null) {
      whereParts.add('${SaleTable.saleDate} = ?');
      whereArgs.add(saleDate);
    }
    if (fromDate != null) {
      whereParts.add('${SaleTable.saleDate} >= ?');
      whereArgs.add(_saleDateFormat.format(fromDate));
    }
    if (toDate != null) {
      whereParts.add('${SaleTable.saleDate} <= ?');
      whereArgs.add(_saleDateFormat.format(toDate));
    }
    if (productId != null) {
      whereParts.add('${SaleTable.productId} = ?');
      whereArgs.add(productId);
    }
    if (customerId != null) {
      whereParts.add('${SaleTable.customerId} = ?');
      whereArgs.add(customerId);
    }
    if (paymentMode != null) {
      whereParts.add('${SaleTable.paymentMode} = ?');
      whereArgs.add(paymentMode.dbValue);
    }

    final rows = await db.query(
      SaleTable.tableName,
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: '${SaleTable.createdAt} DESC',
    );

    return rows.map(SaleModel.fromMap).toList();
  }

  Future<({int orderCount, double revenue})> getSalesSummaryForDate(
    DateTime date,
  ) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS order_count,
        COALESCE(SUM(${SaleTable.totalAmount}), 0) AS revenue
      FROM ${SaleTable.tableName}
      WHERE ${SaleTable.saleDate} = ?
      ''',
      [_saleDateFormat.format(date)],
    );

    final row = rows.first;
    return (
      orderCount: row['order_count'] as int,
      revenue: (row['revenue'] as num).toDouble(),
    );
  }

  Future<void> markSaleSynced({required String id, DateTime? syncedAt}) async {
    final db = await _dbHelper.database;
    await db.update(
      SaleTable.tableName,
      {SaleTable.syncedAt: (syncedAt ?? DateTime.now()).toIso8601String()},
      where: '${SaleTable.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSale(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      SaleTable.tableName,
      where: '${SaleTable.id} = ?',
      whereArgs: [id],
    );
  }
}
