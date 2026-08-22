class PaymentMethod {
  const PaymentMethod({
    this.id,
    required this.name,
    required this.enabled,
    required this.isSystem,
    required this.sortOrder,
  });

  final int? id;
  final String name;
  final bool enabled;
  final bool isSystem;
  final int sortOrder;

  factory PaymentMethod.fromMap(Map<String, Object?> map) => PaymentMethod(
    id: map['id'] as int,
    name: map['name'] as String,
    enabled: map['enabled'] == 1,
    isSystem: map['is_system'] == 1,
    sortOrder: map['sort_order'] as int,
  );

  PaymentMethod copyWith({String? name, bool? enabled, int? sortOrder}) =>
      PaymentMethod(
        id: id,
        name: name ?? this.name,
        enabled: enabled ?? this.enabled,
        isSystem: isSystem,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
