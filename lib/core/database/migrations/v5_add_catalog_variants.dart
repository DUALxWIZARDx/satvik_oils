import 'package:sqflite/sqflite.dart';

import '../../constants/product_catalog.dart';
import '../db_schema.dart';

class V5AddCatalogVariants {
  const V5AddCatalogVariants._();

  static Future<void> migrate(DatabaseExecutor db) async {
    const effectiveFrom = '1970-01-01T00:00:00.000Z';
    final batch = db.batch();

    for (final product in ProductCatalog.products) {
      final baseRows = await db.query(
        ProductPriceTable.tableName,
        columns: [ProductPriceTable.costPrice],
        where:
            '${ProductPriceTable.productId} = ? AND '
            '${ProductPriceTable.quantityVariant} = ?',
        whereArgs: [product.id, '1L'],
        orderBy: '${ProductPriceTable.effectiveFrom} DESC',
        limit: 1,
      );
      final baseCost = baseRows.isEmpty
          ? 0.0
          : (baseRows.first[ProductPriceTable.costPrice] as num).toDouble();

      for (final quantityVariant in product.quantityVariants) {
        final costPrice = quantityVariant == '2L' ? baseCost * 2 : 0.0;
        batch.insert(ProductPriceTable.tableName, {
          ProductPriceTable.id: '${product.id}_$quantityVariant',
          ProductPriceTable.productId: product.id,
          ProductPriceTable.quantityVariant: quantityVariant,
          ProductPriceTable.sellingPrice: 0.0,
          ProductPriceTable.costPrice: costPrice,
          ProductPriceTable.effectiveFrom: effectiveFrom,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    await batch.commit(noResult: true);
  }
}
