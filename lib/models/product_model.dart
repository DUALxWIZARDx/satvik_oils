import '../core/database/db_schema.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String name;
  final bool isActive;

  factory ProductModel.fromMap(Map<String, Object?> map) {
    return ProductModel(
      id: map[ProductTable.id] as String,
      name: map[ProductTable.name] as String,
      isActive: (map[ProductTable.isActive] as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      ProductTable.id: id,
      ProductTable.name: name,
      ProductTable.isActive: isActive ? 1 : 0,
    };
  }

  ProductModel copyWith({String? id, String? name, bool? isActive}) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }
}
