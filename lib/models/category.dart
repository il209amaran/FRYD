class Category {
  const Category({
    this.id,
    required this.name,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Category.fromMap(Map<String, Object?> map) => Category(
    id: map['id'] as int,
    name: map['name'] as String,
    sortOrder: (map['sort_order'] as int?) ?? 0,
    createdAt: DateTime.tryParse(map['created_at'] as String) ?? DateTime(1970),
    updatedAt: DateTime.tryParse(map['updated_at'] as String) ?? DateTime(1970),
  );

  Map<String, Object?> toMap({bool includeId = true}) => {
    if (includeId && id != null) 'id': id,
    'name': name,
    'sort_order': sortOrder,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Category copyWith({
    int? id,
    String? name,
    int? sortOrder,
    DateTime? updatedAt,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
