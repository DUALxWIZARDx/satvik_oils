import 'package:uuid/uuid.dart';

import '../core/database/db_helper.dart';
import '../core/database/db_schema.dart';
import '../models/customer_model.dart';
import '../models/customer_analytics.dart';

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
    bool isMembership = false,
    double membershipFee = 0,
  }) async {
    final customer = CustomerModel(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      address: address,
      createdAt: createdAt ?? DateTime.now(),
      isMembership: isMembership,
      membershipFee: membershipFee,
    );

    final db = await _dbHelper.database;
    await db.insert(CustomerTable.tableName, customer.toMap());
    return customer;
  }

  Future<CustomerModel?> getCustomerByPhone(String phone) async {
    final db = await _dbHelper.database;
    final rows = await db.query(CustomerTable.tableName,
      where: '${CustomerTable.phone} = ?', whereArgs: [phone.trim()], limit: 1);
    return rows.isEmpty ? null : CustomerModel.fromMap(rows.first);
  }

  Future<List<CustomerModel>> getMembershipCustomers() async {
    final db = await _dbHelper.database;
    final rows = await db.query(CustomerTable.tableName,
      where: '${CustomerTable.isMembership} = 1', orderBy: CustomerTable.name);
    return rows.map(CustomerModel.fromMap).toList();
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

  Future<List<CustomerAnalytics>> getCustomerAnalytics() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      WITH order_summaries AS (
        SELECT customer_id, COALESCE(order_id, id) AS order_key,
          CASE WHEN order_id IS NOT NULL AND order_final_total IS NOT NULL
            THEN MAX(order_final_total) ELSE SUM(total_amount) END AS order_total,
          MAX(created_at) AS last_purchase
        FROM sales WHERE customer_id IS NOT NULL
        GROUP BY customer_id, COALESCE(order_id, id)
      )
      SELECT c.*, COUNT(o.order_key) AS order_count,
        COALESCE(SUM(o.order_total), 0) AS total_spent,
        MAX(o.last_purchase) AS last_purchase
      FROM customers c LEFT JOIN order_summaries o ON o.customer_id = c.id
      GROUP BY c.id ORDER BY c.name
    ''');
    return rows.map((row) => CustomerAnalytics(customer: CustomerModel.fromMap(row), orderCount: (row['order_count'] as num).toInt(), totalSpent: (row['total_spent'] as num).toDouble(), lastPurchase: row['last_purchase'] == null ? null : DateTime.parse(row['last_purchase'] as String))).toList();
  }
}
