import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../core/database/db_helper.dart';
import '../core/database/db_schema.dart';
import '../models/dashboard_model.dart';
import '../models/discount_type.dart';
import '../models/payment_mode.dart';
import '../models/sale_model.dart';
import '../models/sale_history_model.dart';
import '../models/analytics_model.dart';

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
    double? orderSubtotal,
    int? orderDiscountPercent,
    double? orderDiscountAmount,
    double? orderFinalTotal,
    String? orderDiscountSource,
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
      orderSubtotal: orderSubtotal,
      orderDiscountPercent: orderDiscountPercent,
      orderDiscountAmount: orderDiscountAmount,
      orderFinalTotal: orderFinalTotal,
      orderDiscountSource: orderDiscountSource,
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

  /// Returns every line belonging to the logical order represented by
  /// [orderKey].  `orderKey` is the same COALESCE(order_id, id) value exposed
  /// by Sale History, so this also supports legacy single-line sales.
  Future<List<SaleModel>> getOrderByKey(String orderKey) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      SaleTable.tableName,
      where:
          '${SaleTable.orderId} = ? '
          'OR (${SaleTable.orderId} IS NULL AND ${SaleTable.id} = ?)',
      whereArgs: [orderKey, orderKey],
      orderBy: '${SaleTable.createdAt} ASC, ${SaleTable.id} ASC',
    );
    return rows.map(SaleModel.fromMap).toList();
  }

  /// Replaces the contents of an existing logical order in one transaction.
  ///
  /// Existing rows are updated first, only surplus old rows are deleted, and
  /// new rows are inserted only when the edited cart contains more lines.
  /// Every replacement line carries [originalCreatedAt], so neither the order
  /// date nor time can change while editing.
  Future<void> updateOrderByKey({
    required String orderKey,
    required DateTime originalCreatedAt,
    required List<SaleModel> updatedLines,
  }) async {
    if (updatedLines.isEmpty) {
      throw ArgumentError.value(
        updatedLines,
        'updatedLines',
        'Cannot be empty',
      );
    }

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final existingRows = await txn.query(
        SaleTable.tableName,
        where:
            '${SaleTable.orderId} = ? '
            'OR (${SaleTable.orderId} IS NULL AND ${SaleTable.id} = ?)',
        whereArgs: [orderKey, orderKey],
        orderBy: '${SaleTable.createdAt} ASC, ${SaleTable.id} ASC',
      );
      if (existingRows.isEmpty) {
        throw StateError('Order no longer exists.');
      }

      for (var index = 0; index < updatedLines.length; index++) {
        // Enforce the original timestamp at the persistence boundary too;
        // callers cannot accidentally turn an edit into a newly dated sale.
        final line = updatedLines[index].copyWith(
          createdAt: originalCreatedAt,
          saleDate: _saleDateFormat.format(originalCreatedAt),
          saleTime: _saleTimeFormat.format(originalCreatedAt),
        );
        if (index < existingRows.length) {
          final existingId = existingRows[index][SaleTable.id] as String;
          await txn.update(
            SaleTable.tableName,
            line.copyWith(id: existingId).toMap(),
            where: '${SaleTable.id} = ?',
            whereArgs: [existingId],
          );
        } else {
          await txn.insert(SaleTable.tableName, line.toMap());
        }
      }

      for (
        var index = updatedLines.length;
        index < existingRows.length;
        index++
      ) {
        await txn.delete(
          SaleTable.tableName,
          where: '${SaleTable.id} = ?',
          whereArgs: [existingRows[index][SaleTable.id] as String],
        );
      }
    });
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

  Future<List<SaleHistoryOrder>> getSaleHistoryOrders(DateTime month) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(month.year, month.month);
    final nextMonth = DateTime(month.year, month.month + 1);
    final rows = await db.rawQuery(
      '''
      WITH order_summaries AS (
        SELECT
          COALESCE(${SaleTable.orderId}, ${SaleTable.id}) AS order_key,
          MAX(${SaleTable.createdAt}) AS latest_created_at,
          CASE
            WHEN ${SaleTable.orderId} IS NOT NULL
              AND ${SaleTable.orderFinalTotal} IS NOT NULL
            THEN MAX(${SaleTable.orderFinalTotal})
            ELSE SUM(${SaleTable.totalAmount})
          END AS total_amount,
          MIN(${SaleTable.paymentMode}) AS payment_mode
        FROM ${SaleTable.tableName}
        WHERE ${SaleTable.saleDate} >= ?
          AND ${SaleTable.saleDate} < ?
        GROUP BY COALESCE(${SaleTable.orderId}, ${SaleTable.id})
      )
      SELECT
        order_summaries.order_key,
        order_summaries.latest_created_at,
        order_summaries.total_amount,
        order_summaries.payment_mode,
        sales.${SaleTable.productNameSnapshot} AS product_name,
        sales.${SaleTable.quantityVariant} AS quantity_variant,
        SUM(
          CASE
            WHEN sales.${SaleTable.unitPriceSnapshot} > 0
            THEN sales.${SaleTable.totalAmount}
              / sales.${SaleTable.unitPriceSnapshot}
            ELSE 0
          END
        ) AS quantity
      FROM order_summaries
      JOIN ${SaleTable.tableName} AS sales
        ON order_summaries.order_key =
          COALESCE(sales.${SaleTable.orderId}, sales.${SaleTable.id})
      WHERE sales.${SaleTable.saleDate} >= ?
        AND sales.${SaleTable.saleDate} < ?
      GROUP BY
        order_summaries.order_key,
        order_summaries.latest_created_at,
        order_summaries.total_amount,
        order_summaries.payment_mode,
        sales.${SaleTable.productNameSnapshot},
        sales.${SaleTable.quantityVariant}
      ORDER BY order_summaries.latest_created_at DESC
      ''',
      [
        _saleDateFormat.format(startDate),
        _saleDateFormat.format(nextMonth),
        _saleDateFormat.format(startDate),
        _saleDateFormat.format(nextMonth),
      ],
    );

    final orders = <String, SaleHistoryOrder>{};
    for (final row in rows) {
      final orderKey = row['order_key'] as String;
      final item = SaleHistoryItem(
        productName: row['product_name'] as String,
        quantityVariant: row['quantity_variant'] as String,
        quantity: (row['quantity'] as num).toDouble(),
      );
      final existingOrder = orders[orderKey];
      if (existingOrder == null) {
        orders[orderKey] = SaleHistoryOrder(
          orderKey: orderKey,
          items: [item],
          totalAmount: (row['total_amount'] as num).toDouble(),
          paymentMode: PaymentMode.fromDbValue(row['payment_mode'] as String),
          createdAt: DateTime.parse(row['latest_created_at'] as String),
        );
      } else {
        orders[orderKey] = SaleHistoryOrder(
          orderKey: orderKey,
          items: [...existingOrder.items, item],
          totalAmount: existingOrder.totalAmount,
          paymentMode: existingOrder.paymentMode,
          createdAt: existingOrder.createdAt,
        );
      }
    }

    return orders.values.toList();
  }

  Future<DashboardSummary> getDashboardSummaryForDate(DateTime date) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      WITH dated_sales AS (
        SELECT *
        FROM ${SaleTable.tableName}
        WHERE ${SaleTable.saleDate} = ?
      ),
      order_totals AS (
        SELECT
          COALESCE(${SaleTable.orderId}, ${SaleTable.id}) AS order_key,
          CASE
            WHEN ${SaleTable.orderId} IS NOT NULL
              AND ${SaleTable.orderFinalTotal} IS NOT NULL
            THEN MAX(${SaleTable.orderFinalTotal})
            ELSE SUM(${SaleTable.totalAmount})
          END AS order_revenue,
          CASE
            WHEN ${SaleTable.orderId} IS NOT NULL
            THEN MAX(COALESCE(${SaleTable.orderDiscountAmount}, 0))
            ELSE 0
          END AS order_discount
        FROM dated_sales
        GROUP BY order_key
      ),
      line_totals AS (
        SELECT
          COALESCE(SUM(${SaleTable.totalAmount}), 0) AS gross_revenue,
          COALESCE(SUM(
            CASE
              WHEN ${SaleTable.unitPriceSnapshot} > 0
              THEN (${SaleTable.totalAmount} / ${SaleTable.unitPriceSnapshot})
                * ${SaleTable.costPriceSnapshot}
              ELSE ${SaleTable.costPriceSnapshot}
            END
          ), 0) AS total_cost
        FROM dated_sales
      )
      SELECT
        COUNT(order_totals.order_key) AS order_count,
        COALESCE(SUM(order_totals.order_revenue), 0) AS sales_revenue,
        (
          line_totals.gross_revenue
          - line_totals.total_cost
          - COALESCE(SUM(order_totals.order_discount), 0)
        ) AS profit
      FROM line_totals
      LEFT JOIN order_totals ON 1 = 1
      ''',
      [_saleDateFormat.format(date)],
    );

    final row = rows.first;
    final orderCount = (row['order_count'] as num).toInt();
    final salesRevenue = (row['sales_revenue'] as num).toDouble();
    final profit = (row['profit'] as num).toDouble();

    return DashboardSummary(
      salesRevenue: salesRevenue,
      profit: profit,
      orderCount: orderCount,
      averageOrderValue: orderCount == 0 ? 0 : salesRevenue / orderCount,
    );
  }

  Future<List<TopSellingOilToday>> getTopSellingOilsForDate(
    DateTime date, {
    int limit = 5,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        ${SaleTable.productNameSnapshot} AS product_name,
        COALESCE(SUM(
          CASE
            WHEN ${SaleTable.unitPriceSnapshot} > 0
            THEN ${SaleTable.totalAmount} / ${SaleTable.unitPriceSnapshot}
            ELSE 0
          END
        ), 0) AS quantity_sold,
        COALESCE(SUM(${SaleTable.totalAmount}), 0) AS revenue
      FROM ${SaleTable.tableName}
      WHERE ${SaleTable.saleDate} = ?
      GROUP BY ${SaleTable.productId}, ${SaleTable.productNameSnapshot}
      ORDER BY quantity_sold DESC, revenue DESC, product_name ASC
      LIMIT ?
      ''',
      [_saleDateFormat.format(date), limit],
    );

    return rows
        .map(
          (row) => TopSellingOilToday(
            productName: row['product_name'] as String,
            quantitySold: (row['quantity_sold'] as num).toDouble(),
            revenue: (row['revenue'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<List<RecentOrderSummary>> getRecentOrdersForDate(
    DateTime date, {
    int limit = 5,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      WITH dated_sales AS (
        SELECT *
        FROM ${SaleTable.tableName}
        WHERE ${SaleTable.saleDate} = ?
      ), recent_orders AS (
        SELECT
          COALESCE(${SaleTable.orderId}, ${SaleTable.id}) AS order_key,
          MAX(${SaleTable.createdAt}) AS latest_created_at,
          MAX(${SaleTable.saleTime}) AS sale_time,
          CASE
            WHEN ${SaleTable.orderId} IS NOT NULL
              AND ${SaleTable.orderFinalTotal} IS NOT NULL
            THEN MAX(${SaleTable.orderFinalTotal})
            ELSE SUM(${SaleTable.totalAmount})
          END AS total_amount,
          MIN(${SaleTable.paymentMode}) AS payment_mode
        FROM dated_sales
        GROUP BY COALESCE(${SaleTable.orderId}, ${SaleTable.id})
        ORDER BY latest_created_at DESC
        LIMIT ?
      )
      SELECT
        recent_orders.order_key,
        recent_orders.latest_created_at,
        recent_orders.sale_time,
        recent_orders.total_amount,
        recent_orders.payment_mode,
        dated_sales.${SaleTable.productNameSnapshot} AS product_name,
        dated_sales.${SaleTable.quantityVariant} AS quantity_variant,
        SUM(
          CASE
            WHEN dated_sales.${SaleTable.unitPriceSnapshot} > 0
            THEN dated_sales.${SaleTable.totalAmount}
              / dated_sales.${SaleTable.unitPriceSnapshot}
            ELSE 0
          END
        ) AS quantity
      FROM recent_orders
      JOIN dated_sales
        ON recent_orders.order_key =
          COALESCE(dated_sales.${SaleTable.orderId}, dated_sales.${SaleTable.id})
      GROUP BY
        recent_orders.order_key,
        recent_orders.latest_created_at,
        recent_orders.sale_time,
        recent_orders.total_amount,
        recent_orders.payment_mode,
        dated_sales.${SaleTable.productNameSnapshot},
        dated_sales.${SaleTable.quantityVariant}
      ORDER BY recent_orders.latest_created_at DESC
      ''',
      [_saleDateFormat.format(date), limit],
    );

    final summaries = <String, RecentOrderSummary>{};
    for (final row in rows) {
      final orderKey = row['order_key'] as String;
      final item =
          '${row['product_name']} (${row['quantity_variant']} x'
          '${_formatQuantity((row['quantity'] as num).toDouble())})';
      final existing = summaries[orderKey];
      if (existing == null) {
        summaries[orderKey] = RecentOrderSummary(
          oilSummary: item,
          time: row['sale_time'] as String,
          totalAmount: (row['total_amount'] as num).toDouble(),
          paymentMode: PaymentMode.fromDbValue(row['payment_mode'] as String),
        );
      } else {
        summaries[orderKey] = RecentOrderSummary(
          oilSummary: '${existing.oilSummary}\n$item',
          time: existing.time,
          totalAmount: existing.totalAmount,
          paymentMode: existing.paymentMode,
        );
      }
    }

    return summaries.values.toList();
  }

  static String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
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

  Future<AnalyticsReport> getAnalytics({
    required DateTime from,
    required DateTime to,
    DateTime? previousFrom,
    DateTime? previousTo,
  }) async {
    final sales = await getSales(fromDate: from, toDate: to);
    final previousSales = previousFrom == null || previousTo == null
        ? const <SaleModel>[]
        : await getSales(fromDate: previousFrom, toDate: previousTo);
    return buildAnalytics(sales, previousSales);
  }

  static AnalyticsReport buildAnalytics(
    List<SaleModel> sales,
    List<SaleModel> previousSales,
  ) {
    AnalyticsSummary summaryFor(List<SaleModel> rows) {
      final groups = <String, List<SaleModel>>{};
      for (final sale in rows) {
        (groups[sale.orderId ?? sale.id] ??= []).add(sale);
      }
      var revenue = 0.0, cost = 0.0;
      for (final lines in groups.values) {
        revenue +=
            lines.first.orderFinalTotal ??
            lines.fold(0.0, (v, line) => v + line.totalAmount);
        for (final line in lines) {
          final quantity = line.unitPriceSnapshot == 0
              ? 0
              : line.totalAmount / line.unitPriceSnapshot;
          cost += quantity * line.costPriceSnapshot;
        }
      }
      return AnalyticsSummary(
        revenue: revenue,
        profit: revenue - cost,
        orders: groups.length,
      );
    }

    final byDay = <String, List<SaleModel>>{};
    for (final sale in sales) {
      (byDay[sale.saleDate] ??= []).add(sale);
    }
    final days =
        byDay.entries
            .map(
              (e) => AnalyticsDay(
                date: DateTime.parse(e.key),
                summary: summaryFor(e.value),
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final orderLines = <String, List<SaleModel>>{};
    for (final sale in sales) {
      (orderLines[sale.orderId ?? sale.id] ??= []).add(sale);
    }
    final products = <String, Map<String, dynamic>>{};
    for (final lines in orderLines.values) {
      final double orderTotal =
          lines.first.orderFinalTotal ??
          lines.fold(0.0, (v, l) => v + l.totalAmount);
      final double subtotal = lines.fold(0.0, (v, l) => v + l.totalAmount);
      for (final l in lines) {
        final allocation = subtotal == 0
            ? 0
            : orderTotal * l.totalAmount / subtotal;
        final qty = l.unitPriceSnapshot == 0
            ? 0
            : l.totalAmount / l.unitPriceSnapshot;
        final p = products.putIfAbsent(
          l.productId,
          () => {
            'name': l.productNameSnapshot,
            'qty': 0.0,
            'revenue': 0.0,
            'profit': 0.0,
            'litres': 0.0,
            'variants': <String, Map<String, double>>{},
          },
        );
        p['qty'] += qty;
        p['revenue'] += allocation;
        p['profit'] += allocation - (qty * l.costPriceSnapshot);
        p['litres'] += qty * _variantLitres(l.quantityVariant);
        final vs = (p['variants'] as Map<String, Map<String, double>>)
            .putIfAbsent(
              l.quantityVariant,
              () => {'qty': 0, 'revenue': 0, 'profit': 0},
            );
        vs['qty'] = (vs['qty'] ?? 0) + qty;
        vs['revenue'] = (vs['revenue'] ?? 0) + allocation;
        vs['profit'] =
            (vs['profit'] ?? 0) + allocation - (qty * l.costPriceSnapshot);
      }
    }
    final productResults = products.entries.map((e) {
      final p = e.value;
      return ProductPerformance(
        productId: e.key,
        name: p['name'],
        quantity: p['qty'],
        revenue: p['revenue'],
        profit: p['profit'],
        litresSold: p['litres'],
        variants: (p['variants'] as Map<String, Map<String, double>>).entries
            .map(
              (v) => VariantPerformance(
                variant: v.key,
                quantity: v.value['qty']!,
                revenue: v.value['revenue']!,
                profit: v.value['profit']!,
              ),
            )
            .toList(),
      );
    }).toList();
    final paymentGroups = <PaymentMode, List<SaleModel>>{};
    for (final lines in orderLines.values) {
      (paymentGroups[lines.first.paymentMode] ??= []).addAll(lines);
    }
    final payments = PaymentMode.values.map((mode) {
      final lines = paymentGroups[mode] ?? const <SaleModel>[];
      return PaymentPerformance(
        mode: mode,
        revenue: summaryFor(lines).revenue,
        orders: <String>{
          for (final line in lines) line.orderId ?? line.id,
        }.length,
      );
    }).toList();
    return AnalyticsReport(
      summary: summaryFor(sales),
      previous: summaryFor(previousSales),
      days: days,
      products: productResults,
      payments: payments,
    );
  }

  static double _variantLitres(String variant) {
    final normalized = variant.trim().toLowerCase();
    if (normalized.endsWith('ml')) {
      final millilitres = double.tryParse(
        normalized.substring(0, normalized.length - 2),
      );
      return (millilitres ?? 0) / 1000;
    }
    if (normalized.endsWith('l')) {
      return double.tryParse(normalized.substring(0, normalized.length - 1)) ??
          0;
    }
    return 0;
  }

  /// Deletes every sales row belonging to a logical order.
  ///
  /// Mirrors the COALESCE(order_id, id) pattern used by every read query:
  ///   • Multi-item orders  — all rows share a non-null order_id; delete by it.
  ///   • Single-item orders — order_id IS NULL; the row's own id is the key.
  ///
  /// Calling code should supply the value returned by
  /// [SaleHistoryOrder.orderKey], which is already the COALESCE result.
  Future<void> deleteOrderByKey(String orderKey) async {
    final db = await _dbHelper.database;
    await db.delete(
      SaleTable.tableName,
      where:
          '${SaleTable.orderId} = ? '
          'OR (${SaleTable.orderId} IS NULL AND ${SaleTable.id} = ?)',
      whereArgs: [orderKey, orderKey],
    );
  }
}
