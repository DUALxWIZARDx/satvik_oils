import 'package:sqflite/sqflite.dart';

import '../../constants/product_catalog.dart';
import '../db_schema.dart';

class V1InitialSchema {
  const V1InitialSchema._();

  static Future<void> migrate(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${ProductTable.tableName} (
        ${ProductTable.id} TEXT PRIMARY KEY,
        ${ProductTable.name} TEXT NOT NULL UNIQUE,
        ${ProductTable.isActive} INTEGER NOT NULL DEFAULT 1
          CHECK (${ProductTable.isActive} IN (0, 1))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${ProductPriceTable.tableName} (
        ${ProductPriceTable.id} TEXT PRIMARY KEY,
        ${ProductPriceTable.productId} TEXT NOT NULL,
        ${ProductPriceTable.quantityVariant} TEXT NOT NULL,
        ${ProductPriceTable.sellingPrice} REAL NOT NULL DEFAULT 0
          CHECK (${ProductPriceTable.sellingPrice} >= 0),
        ${ProductPriceTable.costPrice} REAL NOT NULL DEFAULT 0
          CHECK (${ProductPriceTable.costPrice} >= 0),
        ${ProductPriceTable.effectiveFrom} TEXT NOT NULL,
        FOREIGN KEY (${ProductPriceTable.productId})
          REFERENCES ${ProductTable.tableName} (${ProductTable.id})
          ON UPDATE RESTRICT
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${CustomerTable.tableName} (
        ${CustomerTable.id} TEXT PRIMARY KEY,
        ${CustomerTable.name} TEXT NOT NULL,
        ${CustomerTable.phone} TEXT NOT NULL DEFAULT '',
        ${CustomerTable.address} TEXT NOT NULL DEFAULT '',
        ${CustomerTable.createdAt} TEXT NOT NULL
        ,${CustomerTable.isMembership} INTEGER NOT NULL DEFAULT 0
          CHECK (${CustomerTable.isMembership} IN (0, 1))
        ,${CustomerTable.membershipFee} REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${SaleTable.tableName} (
        ${SaleTable.id} TEXT PRIMARY KEY,
        ${SaleTable.createdAt} TEXT NOT NULL,
        ${SaleTable.saleDate} TEXT NOT NULL,
        ${SaleTable.saleTime} TEXT NOT NULL,
        ${SaleTable.productId} TEXT NOT NULL,
        ${SaleTable.productNameSnapshot} TEXT NOT NULL,
        ${SaleTable.quantityVariant} TEXT NOT NULL,
        ${SaleTable.unitPriceSnapshot} REAL NOT NULL
          CHECK (${SaleTable.unitPriceSnapshot} >= 0),
        ${SaleTable.costPriceSnapshot} REAL NOT NULL
          CHECK (${SaleTable.costPriceSnapshot} >= 0),
        ${SaleTable.discountType} TEXT NOT NULL
          CHECK (${SaleTable.discountType}
            IN ('none', 'percent_5', 'percent_7', 'percent_10', 'percent_12', 'percent_15', 'custom')),
        ${SaleTable.discountValue} REAL NOT NULL DEFAULT 0
          CHECK (${SaleTable.discountValue} >= 0),
        ${SaleTable.totalAmount} REAL NOT NULL
          CHECK (${SaleTable.totalAmount} >= 0),
        ${SaleTable.paymentMode} TEXT NOT NULL
          CHECK (${SaleTable.paymentMode} IN ('cash', 'upi', 'card')),
        ${SaleTable.customerId} TEXT,
        ${SaleTable.orderId} TEXT,
        ${SaleTable.orderSubtotal} REAL,
        ${SaleTable.orderDiscountPercent} INTEGER,
        ${SaleTable.orderDiscountAmount} REAL,
        ${SaleTable.orderFinalTotal} REAL,
        ${SaleTable.orderDiscountSource} TEXT,
        ${SaleTable.syncedAt} TEXT,
        FOREIGN KEY (${SaleTable.productId})
          REFERENCES ${ProductTable.tableName} (${ProductTable.id})
          ON UPDATE RESTRICT
          ON DELETE RESTRICT,
        FOREIGN KEY (${SaleTable.customerId})
          REFERENCES ${CustomerTable.tableName} (${CustomerTable.id})
          ON UPDATE RESTRICT
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppSettingsTable.tableName} (
        ${AppSettingsTable.key} TEXT PRIMARY KEY,
        ${AppSettingsTable.value} TEXT NOT NULL,
        ${AppSettingsTable.updatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sales_sale_date
      ON ${SaleTable.tableName} (${SaleTable.saleDate})
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sales_product_id
      ON ${SaleTable.tableName} (${SaleTable.productId})
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sales_customer_id
      ON ${SaleTable.tableName} (${SaleTable.customerId})
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sales_payment_mode
      ON ${SaleTable.tableName} (${SaleTable.paymentMode})
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_product_prices_lookup
      ON ${ProductPriceTable.tableName} (
        ${ProductPriceTable.productId},
        ${ProductPriceTable.quantityVariant},
        ${ProductPriceTable.effectiveFrom}
      )
    ''');

    await _seedDefaultProducts(db);
  }

  static Future<void> _seedDefaultProducts(DatabaseExecutor db) async {
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
