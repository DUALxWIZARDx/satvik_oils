import 'package:sqflite/sqflite.dart';

import '../db_schema.dart';

class V2AddOrderIdToSales {
  static Future<void> migrate(DatabaseExecutor db) async {
    // Add `order_id` TEXT column if it does not already exist.
    // Use PRAGMA table_info to inspect existing columns
    final info = await db.rawQuery("PRAGMA table_info('${SaleTable.tableName}')");
    final existingColumns = info.map((r) => (r['name'] as String).toLowerCase()).toSet();

    if (!existingColumns.contains(SaleTable.orderId.toLowerCase())) {
      await db.execute('ALTER TABLE ${SaleTable.tableName} ADD COLUMN ${SaleTable.orderId} TEXT');
    }
  }
}
