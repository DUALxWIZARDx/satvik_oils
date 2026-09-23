import '../core/database/db_schema.dart';

class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.createdAt,
    this.isMembership = false,
    this.membershipFee = 0,
  });

  final String id;
  final String name;
  final String phone;
  final String address;
  final DateTime createdAt;
  final bool isMembership;
  final double membershipFee;

  factory CustomerModel.fromMap(Map<String, Object?> map) {
    return CustomerModel(
      id: map[CustomerTable.id] as String,
      name: map[CustomerTable.name] as String,
      phone: map[CustomerTable.phone] as String,
      address: map[CustomerTable.address] as String,
      createdAt: DateTime.parse(map[CustomerTable.createdAt] as String),
      isMembership: (map[CustomerTable.isMembership] as num? ?? 0) == 1,
      membershipFee: (map[CustomerTable.membershipFee] as num? ?? 0).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      CustomerTable.id: id,
      CustomerTable.name: name,
      CustomerTable.phone: phone,
      CustomerTable.address: address,
      CustomerTable.createdAt: createdAt.toIso8601String(),
      CustomerTable.isMembership: isMembership ? 1 : 0,
      CustomerTable.membershipFee: membershipFee,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    DateTime? createdAt,
    bool? isMembership,
    double? membershipFee,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      isMembership: isMembership ?? this.isMembership,
      membershipFee: membershipFee ?? this.membershipFee,
    );
  }
}
