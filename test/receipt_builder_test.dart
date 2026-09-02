import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fryd/features/business/data/business_settings_repository.dart';
import 'package:fryd/features/business/data/receipt_settings_repository.dart';
import 'package:fryd/features/printer/services/receipt_builder.dart';
import 'package:fryd/models/business_settings.dart';
import 'package:fryd/models/order.dart';
import 'package:fryd/models/receipt_settings.dart';

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
  final builder = ReceiptBuilder(
    businessSettingsRepository: _FakeBusinessSettingsRepository(),
    receiptSettingsRepository: _FakeReceiptSettingsRepository(),
  );

  test('prints a trimmed customer name when provided', () async {
    final bytes = await builder.build(
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
    final bytes = await builder.build(
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

class _FakeBusinessSettingsRepository extends BusinessSettingsRepository {
  @override
  Future<BusinessSettings> get() async => const BusinessSettings(
    businessName: 'FRYD',
    businessType: 'Restaurant',
    address: '',
    phone: '',
    email: '',
    country: 'India',
    currencyCode: 'USD',
    taxRegistrationNumber: '',
    taxEnabled: false,
    taxName: 'GST',
    taxRate: 0,
    taxInclusive: false,
    setupCompleted: true,
  );
}

class _FakeReceiptSettingsRepository extends ReceiptSettingsRepository {
  @override
  Future<ReceiptSettings> get() async => const ReceiptSettings(
    showBusinessName: true,
    showAddress: false,
    showPhone: false,
    showEmail: false,
    showTaxNumber: false,
    header: '',
    footer: '',
  );
}
