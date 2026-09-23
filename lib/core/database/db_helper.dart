import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'db_schema.dart';
import 'migrations/v1_initial_schema.dart';
import 'migrations/v2_add_order_id_to_sales.dart';
import 'migrations/v3_add_order_summary_to_sales.dart';
import 'migrations/v4_add_membership.dart';

class DbHelper {
  DbHelper._();

  static final DbHelper instance = DbHelper._();
  static const String databaseName = 'satvik_oils.db';
  static const int schemaVersion = DbSchema.version;

  static final Map<int, Future<void> Function(DatabaseExecutor db)>
  _migrations = {
    1: V1InitialSchema.migrate,
    2: V2AddOrderIdToSales.migrate,
    3: V3AddOrderSummaryToSales.migrate,
    4: V4AddMembership.migrate,
  };

  Database? _database;

  Future<void> initialize() async {
    await database;
  }

  Future<Database> get database async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final openedDatabase = await _openDatabase();
    _database = openedDatabase;
    return openedDatabase;
  }

  Future<void> close() async {
    final existingDatabase = _database;
    if (existingDatabase == null) {
      return;
    }

    await existingDatabase.close();
    _database = null;
  }

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final databasePath = p.join(databasesPath, databaseName);

    return openDatabase(
      databasePath,
      version: schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _runMigrations(db, fromVersion: 0, toVersion: version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _runMigrations(
          db,
          fromVersion: oldVersion,
          toVersion: newVersion,
        );
      },
      onOpen: (db) async {
        await _repairEmptyV1Database(db);
      },
    );
  }

  Future<void> _runMigrations(
    DatabaseExecutor db, {
    required int fromVersion,
    required int toVersion,
  }) async {
    for (var version = fromVersion + 1; version <= toVersion; version++) {
      final migration = _migrations[version];
      if (migration == null) {
        throw StateError('Missing database migration for version $version');
      }

      await migration(db);
    }
  }

  Future<void> _repairEmptyV1Database(Database db) async {
    final requiredTables = {
      ProductTable.tableName,
      ProductPriceTable.tableName,
      CustomerTable.tableName,
      SaleTable.tableName,
      AppSettingsTable.tableName,
    };
    final existingTables = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ?',
      whereArgs: ['table'],
    );
    final existingTableNames = existingTables
        .map((table) => table['name'] as String)
        .toSet();

    if (!existingTableNames.containsAll(requiredTables)) {
      await V1InitialSchema.migrate(db);
    }
  }
}
