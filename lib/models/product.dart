import 'category.dart';

class Product {
  const Product({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final Category category;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Product.fromMap(Map<String, Object?> map) => Product(
    id: map['id'] as int,
    name: map['name'] as String,
    category: Category(
      id: map['category_id'] as int,
      name: map['category_name'] as String,
      sortOrder: (map['category_sort_order'] as int?) ?? 0,
      createdAt:
          DateTime.tryParse(map['category_created_at'] as String) ??
          DateTime(1970),
      updatedAt:
          DateTime.tryParse(map['category_updated_at'] as String) ??
          DateTime(1970),
    ),
    price: (map['price'] as num).toDouble(),
    createdAt: DateTime.tryParse(map['created_at'] as String) ?? DateTime(1970),
    updatedAt: DateTime.tryParse(map['updated_at'] as String) ?? DateTime(1970),
  );

  Map<String, Object?> toMap({bool includeId = true}) => {
    if (includeId && id != null) 'id': id,
    'name': name,
    'category_id': category.id,
    'price': price,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Product copyWith({
    int? id,
    String? name,
    Category? category,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    price: price ?? this.price,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
