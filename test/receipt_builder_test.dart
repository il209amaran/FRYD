import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fryd/features/printer/services/receipt_builder.dart';
import 'package:fryd/models/order.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final createdAt = DateTime(2026, 8, 24, 10, 30);
  final order = RestaurantOrder(
    id: 1,
    orderNumber: 'ORD-0001',
    status: OrderStatus.open,
    subtotal: 100,
    total: 100,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  test('prints a trimmed customer name when provided', () async {
    final bytes = await ReceiptBuilder().build(
      order: order,
      items: const [],
      customerName: '  Amila Kumar  ',
    );

    expect(
      latin1.decode(bytes, allowInvalid: true),
      contains('Customer: Amila Kumar'),
    );
  });

  test('does not print a customer line when blank', () async {
    final bytes = await ReceiptBuilder().build(
      order: order,
      items: const [],
      customerName: '   ',
    );

    expect(
      latin1.decode(bytes, allowInvalid: true),
      isNot(contains('Customer:')),
    );
  });
}
