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
    this.taxName = 'GST',
    this.taxRate = 0,
    this.taxAmount = 0,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.paymentMethodId,
    this.paymentMethodName,
  });

  final int id;
  final String orderNumber;
  final OrderStatus status;
  final double subtotal;
  final String taxName;
  final double taxRate;
  final double taxAmount;
  final double total;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;
  final int? paymentMethodId;
  final String? paymentMethodName;

  bool get isOpen => status == OrderStatus.open;

  factory RestaurantOrder.fromMap(Map<String, Object?> map) => RestaurantOrder(
    id: map['id'] as int,
    orderNumber: map['order_number'] as String,
    status: OrderStatus.fromDatabase(map['status'] as String),
    subtotal: (map['subtotal'] as num).toDouble(),
    taxName: (map['tax_name'] as String?) ?? 'GST',
    taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
    taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
    total: (map['total'] as num).toDouble(),
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    closedAt: map['closed_at'] == null
        ? null
        : DateTime.parse(map['closed_at'] as String),
    paymentMethodId: map['payment_method_id'] as int?,
    paymentMethodName: map['payment_method_name'] as String?,
  );
}
