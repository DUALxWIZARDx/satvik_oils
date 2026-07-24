import 'package:sqflite/sqflite.dart';

import '../core/database/db_helper.dart';
import '../core/database/db_schema.dart';

class SettingsRepository {
  SettingsRepository({DbHelper? dbHelper})
    : _dbHelper = dbHelper ?? DbHelper.instance;

  final DbHelper _dbHelper;

  Future<String?> getString(String key) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      AppSettingsTable.tableName,
      columns: [AppSettingsTable.value],
      where: '${AppSettingsTable.key} = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first[AppSettingsTable.value] as String;
  }

  Future<void> setString(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(AppSettingsTable.tableName, {
      AppSettingsTable.key: key,
      AppSettingsTable.value: value,
      AppSettingsTable.updatedAt: DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DateTime?> getDateTime(String key) async {
    final value = await getString(key);
    return value == null ? null : DateTime.parse(value);
  }

  Future<void> setDateTime(String key, DateTime value) async {
    await setString(key, value.toIso8601String());
  }

  Future<void> remove(String key) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppSettingsTable.tableName,
      where: '${AppSettingsTable.key} = ?',
      whereArgs: [key],
    );
  }
}
