class Combo {
  const Combo({
    this.id,
    required this.name,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Combo.fromMap(Map<String, Object?> map) => Combo(
    id: map['id'] as int,
    name: map['name'] as String,
    price: (map['price'] as num).toDouble(),
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  Map<String, Object?> toMap({bool includeId = true}) => {
    if (includeId && id != null) 'id': id,
    'name': name,
    'price': price,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Combo copyWith({int? id, String? name, double? price, DateTime? updatedAt}) =>
      Combo(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
