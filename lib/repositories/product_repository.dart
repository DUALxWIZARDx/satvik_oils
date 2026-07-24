import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/product_catalog.dart';
import '../core/database/db_helper.dart';
import '../core/database/db_schema.dart';
import '../models/product_model.dart';

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
    final db = await _dbHelper.database;
    final rows = await db.query(
      ProductPriceTable.tableName,
      columns: [ProductPriceTable.sellingPrice, ProductPriceTable.costPrice],
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
    return (
      costPrice: (row[ProductPriceTable.costPrice] as num).toDouble(),
      sellingPrice: (row[ProductPriceTable.sellingPrice] as num).toDouble(),
    );
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
