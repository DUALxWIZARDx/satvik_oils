import 'package:sqflite/sqflite.dart';

import '../db_schema.dart';

class V4AddMembership {
  const V4AddMembership._();

  static Future<void> migrate(DatabaseExecutor db) async {
    final customerColumns = await db.rawQuery('PRAGMA table_info(${CustomerTable.tableName})');
    final customerNames = customerColumns.map((row) => row['name'] as String).toSet();
    if (!customerNames.contains(CustomerTable.isMembership)) {
      await db.execute('ALTER TABLE ${CustomerTable.tableName} ADD COLUMN ${CustomerTable.isMembership} INTEGER NOT NULL DEFAULT 0');
    }
    if (!customerNames.contains(CustomerTable.membershipFee)) {
      await db.execute('ALTER TABLE ${CustomerTable.tableName} ADD COLUMN ${CustomerTable.membershipFee} REAL NOT NULL DEFAULT 0');
    }

    final saleColumns = await db.rawQuery('PRAGMA table_info(${SaleTable.tableName})');
    final saleNames = saleColumns.map((row) => row['name'] as String).toSet();
    if (!saleNames.contains(SaleTable.orderDiscountSource)) {
      await db.execute('ALTER TABLE ${SaleTable.tableName} ADD COLUMN ${SaleTable.orderDiscountSource} TEXT');
    }
  }
}
