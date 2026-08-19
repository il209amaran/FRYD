enum OrderStatus {
  open('OPEN'),
  closed('CLOSED');

  const OrderStatus(this.databaseValue);
  final String databaseValue;

  static OrderStatus fromDatabase(String value) =>
      value == closed.databaseValue ? closed : open;
}

class RestaurantOrder {
  const RestaurantOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
  });

  final int id;
  final String orderNumber;
  final OrderStatus status;
  final double subtotal;
  final double total;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  bool get isOpen => status == OrderStatus.open;

  factory RestaurantOrder.fromMap(Map<String, Object?> map) => RestaurantOrder(
    id: map['id'] as int,
    orderNumber: map['order_number'] as String,
    status: OrderStatus.fromDatabase(map['status'] as String),
    subtotal: (map['subtotal'] as num).toDouble(),
    total: (map['total'] as num).toDouble(),
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    closedAt: map['closed_at'] == null
        ? null
        : DateTime.parse(map['closed_at'] as String),
  );
}
