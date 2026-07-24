import 'package:uuid/uuid.dart';

import '../core/database/db_helper.dart';
import '../core/database/db_schema.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  CustomerRepository({DbHelper? dbHelper, Uuid? uuid})
    : _dbHelper = dbHelper ?? DbHelper.instance,
      _uuid = uuid ?? const Uuid();

  final DbHelper _dbHelper;
  final Uuid _uuid;

  Future<CustomerModel> createCustomer({
    required String name,
    String phone = '',
    String address = '',
    DateTime? createdAt,
  }) async {
    final customer = CustomerModel(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      address: address,
      createdAt: createdAt ?? DateTime.now(),
    );

    final db = await _dbHelper.database;
    await db.insert(CustomerTable.tableName, customer.toMap());
    return customer;
  }

  Future<List<CustomerModel>> getCustomers({String? searchTerm}) async {
    final db = await _dbHelper.database;
    final trimmedSearchTerm = searchTerm?.trim();
    final hasSearchTerm =
        trimmedSearchTerm != null && trimmedSearchTerm.isNotEmpty;

    final rows = await db.query(
      CustomerTable.tableName,
      where: hasSearchTerm
          ? '${CustomerTable.name} LIKE ? OR ${CustomerTable.phone} LIKE ?'
          : null,
      whereArgs: hasSearchTerm
          ? ['%$trimmedSearchTerm%', '%$trimmedSearchTerm%']
          : null,
      orderBy: CustomerTable.name,
    );

    return rows.map(CustomerModel.fromMap).toList();
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      CustomerTable.tableName,
      where: '${CustomerTable.id} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return CustomerModel.fromMap(rows.first);
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    final db = await _dbHelper.database;
    await db.update(
      CustomerTable.tableName,
      customer.toMap(),
      where: '${CustomerTable.id} = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> deleteCustomer(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      CustomerTable.tableName,
      where: '${CustomerTable.id} = ?',
      whereArgs: [id],
    );
  }
}
