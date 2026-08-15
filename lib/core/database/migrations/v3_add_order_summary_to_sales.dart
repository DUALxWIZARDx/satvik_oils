import 'package:sqflite/sqflite.dart';

import '../db_schema.dart';

class V3AddOrderSummaryToSales {
  static Future<void> migrate(DatabaseExecutor db) async {
    final info = await db.rawQuery("PRAGMA table_info('${SaleTable.tableName}')");
    final existingColumns = info.map((r) => (r['name'] as String).toLowerCase()).toSet();

    if (!existingColumns.contains(SaleTable.orderSubtotal.toLowerCase())) {
      await db.execute('ALTER TABLE ${SaleTable.tableName} ADD COLUMN ${SaleTable.orderSubtotal} REAL');
    }

    if (!existingColumns.contains(SaleTable.orderDiscountPercent.toLowerCase())) {
      await db.execute('ALTER TABLE ${SaleTable.tableName} ADD COLUMN ${SaleTable.orderDiscountPercent} INTEGER');
    }

    if (!existingColumns.contains(SaleTable.orderDiscountAmount.toLowerCase())) {
      await db.execute('ALTER TABLE ${SaleTable.tableName} ADD COLUMN ${SaleTable.orderDiscountAmount} REAL');
    }

    if (!existingColumns.contains(SaleTable.orderFinalTotal.toLowerCase())) {
      await db.execute('ALTER TABLE ${SaleTable.tableName} ADD COLUMN ${SaleTable.orderFinalTotal} REAL');
    }
  }
}
