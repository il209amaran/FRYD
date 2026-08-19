import 'combo.dart';
import 'complement.dart';
import 'product.dart';

enum OrderItemType {
  product('PRODUCT'),
  combo('COMBO'),
  complement('COMPLEMENT');

  const OrderItemType(this.databaseValue);
  final String databaseValue;
}

class OrderItem {
  const OrderItem({
    this.id,
    this.orderId,
    required this.productId,
    required this.comboId,
    required this.complementId,
    required this.itemType,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.savedLineTotal,
  });

  final int? id;
  final int? orderId;
  final int? productId;
  final int? comboId;
  final int? complementId;
  final OrderItemType itemType;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double? savedLineTotal;

  double get total => savedLineTotal ?? unitPrice * quantity;
  bool get isComplementary => itemType == OrderItemType.complement;

  factory OrderItem.fromProduct(Product product) => OrderItem(
    productId: product.id,
    comboId: null,
    complementId: null,
    itemType: OrderItemType.product,
    productName: product.name,
    unitPrice: product.price,
    quantity: 1,
  );

  factory OrderItem.fromCombo(Combo combo) => OrderItem(
    productId: null,
    comboId: combo.id,
    complementId: null,
    itemType: OrderItemType.combo,
    productName: combo.name,
    unitPrice: combo.price,
    quantity: 1,
  );

  factory OrderItem.fromComplement(Complement complement) => OrderItem(
    productId: null,
    comboId: null,
    complementId: complement.id,
    itemType: OrderItemType.complement,
    productName: complement.name,
    unitPrice: 0,
    quantity: 1,
  );

  factory OrderItem.fromMap(Map<String, Object?> map) => OrderItem(
    id: map['id'] as int,
    orderId: map['order_id'] as int,
    productId: map['product_id'] as int?,
    comboId: map['combo_id'] as int?,
    complementId: map['complement_id'] as int?,
    itemType: switch (map['item_type']) {
      'COMBO' => OrderItemType.combo,
      'COMPLEMENT' => OrderItemType.complement,
      _ => OrderItemType.product,
    },
    productName: map['product_name'] as String,
    unitPrice: (map['unit_price'] as num).toDouble(),
    quantity: map['quantity'] as int,
    savedLineTotal: (map['line_total'] as num?)?.toDouble(),
  );

  OrderItem copyWith({int? quantity}) => OrderItem(
    id: id,
    orderId: orderId,
    productId: productId,
    comboId: comboId,
    complementId: complementId,
    itemType: itemType,
    productName: productName,
    unitPrice: unitPrice,
    quantity: quantity ?? this.quantity,
    savedLineTotal: quantity == null ? savedLineTotal : null,
  );
}
