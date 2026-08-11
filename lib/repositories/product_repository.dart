import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/product_catalog.dart';
import '../core/database/db_helper.dart';
import '../core/database/db_schema.dart';
import '../models/product_model.dart';

typedef CurrentProductPrice = ({
  String quantityVariant,
  double costPrice,
  double sellingPrice,
  DateTime effectiveFrom,
  bool isPlaceholder,
});

class ProductRepository {
  ProductRepository({DbHelper? dbHelper, Uuid? uuid})
    : _dbHelper = dbHelper ?? DbHelper.instance,
      _uuid = uuid ?? const Uuid();

  final DbHelper _dbHelper;
  final Uuid _uuid;

  Future<List<ProductModel>> getProducts({bool includeInactive = false}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      ProductTable.tableName,
      where: includeInactive ? null : '${ProductTable.isActive} = ?',
      whereArgs: includeInactive ? null : [1],
      orderBy: ProductTable.name,
    );

    return rows.map(ProductModel.fromMap).toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      ProductTable.tableName,
      where: '${ProductTable.id} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return ProductModel.fromMap(rows.first);
  }

  Future<void> upsertProduct(ProductModel product) async {
    final db = await _dbHelper.database;
    final insertedRowId = await db.insert(
      ProductTable.tableName,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    if (insertedRowId == 0) {
      await db.update(
        ProductTable.tableName,
        product.toMap(),
        where: '${ProductTable.id} = ?',
        whereArgs: [product.id],
      );
    }
  }

  Future<void> setProductActive({
    required String productId,
    required bool isActive,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      ProductTable.tableName,
      {ProductTable.isActive: isActive ? 1 : 0},
      where: '${ProductTable.id} = ?',
      whereArgs: [productId],
    );
  }

  Future<({double costPrice, double sellingPrice})?> getCurrentPrice({
    required String productId,
    required String quantityVariant,
  }) async {
    final currentPrice = await getCurrentPriceDetails(
      productId: productId,
      quantityVariant: quantityVariant,
    );

    if (currentPrice == null) {
      return null;
    }

    return (
      costPrice: currentPrice.costPrice,
      sellingPrice: currentPrice.sellingPrice,
    );
  }

  Future<CurrentProductPrice?> getCurrentPriceDetails({
    required String productId,
    required String quantityVariant,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      ProductPriceTable.tableName,
      columns: [
        ProductPriceTable.quantityVariant,
        ProductPriceTable.sellingPrice,
        ProductPriceTable.costPrice,
        ProductPriceTable.effectiveFrom,
      ],
      where:
          '${ProductPriceTable.productId} = ? AND '
          '${ProductPriceTable.quantityVariant} = ?',
      whereArgs: [productId, quantityVariant],
      orderBy: '${ProductPriceTable.effectiveFrom} DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    final sellingPrice = (row[ProductPriceTable.sellingPrice] as num).toDouble();
    final costPrice = (row[ProductPriceTable.costPrice] as num).toDouble();
    final effectiveFrom = DateTime.parse(
      row[ProductPriceTable.effectiveFrom] as String,
    );
    final isPlaceholder = sellingPrice == 0.0 &&
        costPrice == 0.0 &&
        effectiveFrom == DateTime.utc(1970, 1, 1);

    return (
      quantityVariant: row[ProductPriceTable.quantityVariant] as String,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      effectiveFrom: effectiveFrom,
      isPlaceholder: isPlaceholder,
    );
  }

  Future<List<CurrentProductPrice>> getCurrentPrices({
    required String productId,
  }) async {
    final quantityVariants = await getQuantityVariants(productId);
    final currentPrices = <CurrentProductPrice>[];

    for (final quantityVariant in quantityVariants) {
      final currentPrice = await getCurrentPriceDetails(
        productId: productId,
        quantityVariant: quantityVariant,
      );

      if (currentPrice != null) {
        currentPrices.add(currentPrice);
      }
    }

    return currentPrices;
  }

  Future<void> savePrice({
    required String productId,
    required String quantityVariant,
    required double sellingPrice,
    required double costPrice,
    DateTime? effectiveFrom,
  }) async {
    final db = await _dbHelper.database;
    await db.insert(ProductPriceTable.tableName, {
      ProductPriceTable.id: _uuid.v4(),
      ProductPriceTable.productId: productId,
      ProductPriceTable.quantityVariant: quantityVariant,
      ProductPriceTable.sellingPrice: sellingPrice,
      ProductPriceTable.costPrice: costPrice,
      ProductPriceTable.effectiveFrom: (effectiveFrom ?? DateTime.now())
          .toIso8601String(),
    });
  }

  int _variantVolumeMl(String variant) {
    if (variant.endsWith('ml')) {
      return int.tryParse(variant.replaceAll('ml', '')) ?? 0;
    }

    if (variant.endsWith('L')) {
      final numPart = variant.replaceAll('L', '');
      final parsed = double.tryParse(numPart);
      if (parsed == null) return 0;
      return (parsed * 1000).toInt();
    }

    return 0;
  }

  /// Save base 1L cost and propagate calculated cost prices for all variants.
  /// Selling price for non-1L variants is preserved from their current selling price.
  Future<void> saveBaseCostAndPropagate({
    required String productId,
    required double baseCostPrice1L,
    required double sellingPriceFor1L,
    DateTime? effectiveFrom,
  }) async {
    // Determine variants to update
    final product = ProductCatalog.products.firstWhere((p) => p.id == productId);
    final variants = product.quantityVariants;

    // Insert price row for each variant with calculated cost and appropriate selling price
    for (final variant in variants) {
      final volumeMl = _variantVolumeMl(variant);
      final multiplier = volumeMl / 1000.0;
      final calculatedCost = (baseCostPrice1L * multiplier);

      double sellingPrice = 0.0;
      if (variant == '1L') {
        sellingPrice = sellingPriceFor1L;
      } else {
        final current = await getCurrentPriceDetails(productId: productId, quantityVariant: variant);
        sellingPrice = current?.sellingPrice ?? 0.0;
      }

      await savePrice(
        productId: productId,
        quantityVariant: variant,
        sellingPrice: sellingPrice,
        costPrice: double.parse(calculatedCost.toStringAsFixed(2)),
        effectiveFrom: effectiveFrom,
      );
    }
  }

  Future<List<String>> getQuantityVariants(String productId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      ProductPriceTable.tableName,
      distinct: true,
      columns: [ProductPriceTable.quantityVariant],
      where: '${ProductPriceTable.productId} = ?',
      whereArgs: [productId],
      orderBy: ProductPriceTable.quantityVariant,
    );

    final availableVariants = rows
        .map((row) => row[ProductPriceTable.quantityVariant] as String)
        .toSet();

    return ProductCatalog.quantityVariants
        .where(availableVariants.contains)
        .toList();
  }

  Future<void> ensureDefaultProductsSeeded() async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    const effectiveFrom = '1970-01-01T00:00:00.000Z';

    for (final product in ProductCatalog.products) {
      batch.insert(ProductTable.tableName, {
        ProductTable.id: product.id,
        ProductTable.name: product.name,
        ProductTable.isActive: 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      for (final quantityVariant in product.quantityVariants) {
        batch.insert(ProductPriceTable.tableName, {
          ProductPriceTable.id: '${product.id}_$quantityVariant',
          ProductPriceTable.productId: product.id,
          ProductPriceTable.quantityVariant: quantityVariant,
          ProductPriceTable.sellingPrice: 0.0,
          ProductPriceTable.costPrice: 0.0,
          ProductPriceTable.effectiveFrom: effectiveFrom,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    await batch.commit(noResult: true);
  }
}
