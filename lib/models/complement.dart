class Complement {
  const Complement({
    this.id,
    required this.name,
    required this.minimumOrderValue,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final double minimumOrderValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Complement.fromMap(Map<String, Object?> map) => Complement(
    id: map['id'] as int,
    name: map['name'] as String,
    minimumOrderValue: (map['minimum_order_value'] as num).toDouble(),
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  Map<String, Object?> toMap({bool includeId = true}) => {
    if (includeId && id != null) 'id': id,
    'name': name,
    'minimum_order_value': minimumOrderValue,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Complement copyWith({
    int? id,
    String? name,
    double? minimumOrderValue,
    DateTime? updatedAt,
  }) => Complement(
    id: id ?? this.id,
    name: name ?? this.name,
    minimumOrderValue: minimumOrderValue ?? this.minimumOrderValue,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
