import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DbHelper {
  DbHelper._();

  static final DbHelper instance = DbHelper._();
  static const String databaseName = 'satvik_oils.db';
  static const int schemaVersion = 1;

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
      onCreate: (db, version) async {},
    );
  }
}
