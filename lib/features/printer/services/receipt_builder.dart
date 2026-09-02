import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../core/utils/date_time_formatter.dart';
import '../../../models/order.dart';
import '../../../models/order_item.dart';
import '../../business/data/business_settings_repository.dart';
import '../../business/data/receipt_settings_repository.dart';
import '../../settings/data/complement_settings_repository.dart';

class ReceiptBuilder {
  ReceiptBuilder({
    BusinessSettingsRepository? businessSettingsRepository,
    ReceiptSettingsRepository? receiptSettingsRepository,
    ComplementSettingsRepository? complementSettingsRepository,
  }) : _businessSettingsRepository =
           businessSettingsRepository ?? BusinessSettingsRepository(),
       _receiptSettingsRepository =
           receiptSettingsRepository ?? ReceiptSettingsRepository(),
       _complementSettingsRepository =
           complementSettingsRepository ?? ComplementSettingsRepository();

  final BusinessSettingsRepository _businessSettingsRepository;
  final ReceiptSettingsRepository _receiptSettingsRepository;
  final ComplementSettingsRepository _complementSettingsRepository;

  Future<List<int>> build({
    required RestaurantOrder order,
    required List<OrderItem> items,
    String? customerName,
  }) async {
    final business = await _businessSettingsRepository.get();
    final receipt = await _receiptSettingsRepository.get();
    final complementsEnabled = await _complementSettingsRepository.isEnabled();
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];
    if (receipt.showBusinessName && business.businessName.isNotEmpty) {
      bytes.addAll(
        generator.text(
          business.businessName,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
      );
    }
    if (receipt.header.isNotEmpty) {
      bytes.addAll(
        generator.text(
          receipt.header,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
      );
    }
    for (final line in [
      if (receipt.showAddress) business.address,
      if (receipt.showPhone && business.phone.isNotEmpty)
        'Phone: ${business.phone}',
      if (receipt.showEmail && business.email.isNotEmpty)
        'Email: ${business.email}',
      if (receipt.showTaxNumber && business.taxRegistrationNumber.isNotEmpty)
        '${order.taxName}: ${business.taxRegistrationNumber}',
    ]) {
      if (line.isNotEmpty) {
        bytes.addAll(
          generator.text(line, styles: const PosStyles(align: PosAlign.center)),
        );
      }
    }
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(generator.text('Order: ${order.orderNumber}'));
    final trimmedCustomerName = customerName?.trim();
    if (trimmedCustomerName != null && trimmedCustomerName.isNotEmpty) {
      bytes.addAll(generator.text('Customer: $trimmedCustomerName'));
    }
    bytes.addAll(generator.text('Date : ${formatDate(order.createdAt)}'));
    bytes.addAll(generator.text('Time : ${formatTime(order.createdAt)}'));
    bytes.addAll(generator.hr(ch: '-'));

    for (final item in items.where(
      (item) => complementsEnabled || !item.isComplementary,
    )) {
      bytes.addAll(
        generator.text(
          item.isComplementary
              ? 'Complimentary ${item.productName}'
              : item.productName,
          styles: const PosStyles(bold: true),
        ),
      );
      final details = item.isComplementary
          ? '  COMPLIMENTARY'
          : '  ${item.quantity} x ${_money(item.unitPrice, business.currency.symbol)}';
      bytes.addAll(
        generator.row([
          PosColumn(text: details, width: 8),
          PosColumn(
            text: item.isComplementary
                ? 'FREE'
                : _money(item.total, business.currency.symbol),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
      bytes.addAll(generator.feed(1));
    }

    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(
      _totalRow(
        generator,
        'Subtotal',
        order.subtotal,
        business.currency.symbol,
      ),
    );
    if (order.taxAmount > 0) {
      bytes.addAll(
        _totalRow(
          generator,
          '${order.taxName} ${_rate(order.taxRate)}%',
          order.taxAmount,
          business.currency.symbol,
        ),
      );
    }
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(
      _totalRow(
        generator,
        'TOTAL',
        order.total,
        business.currency.symbol,
        bold: true,
      ),
    );
    if (order.paymentMethodName case final payment?) {
      bytes.addAll(generator.text('Payment: $payment'));
    }
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(generator.feed(1));
    for (final line in receipt.footer.split('\n')) {
      if (line.trim().isNotEmpty) {
        bytes.addAll(
          generator.text(
            line.trim(),
            styles: const PosStyles(align: PosAlign.center),
          ),
        );
      }
    }
    bytes.addAll(generator.feed(4));
    return bytes;
  }

  Future<List<int>> buildTestPrint() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    return [
      ...generator.text(
        'FRYD',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
      ...generator.feed(1),
      ...generator.text(
        'Printer connected successfully.',
        styles: const PosStyles(align: PosAlign.center),
      ),
      ...generator.text(
        'Test Print OK',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
      ...generator.feed(4),
    ];
  }

  List<int> _totalRow(
    Generator generator,
    String label,
    double value,
    String symbol, {
    bool bold = false,
  }) => generator.row([
    PosColumn(
      text: label,
      width: 7,
      styles: PosStyles(bold: bold),
    ),
    PosColumn(
      text: _money(value, symbol),
      width: 5,
      styles: PosStyles(align: PosAlign.right, bold: bold),
    ),
  ]);

  String _money(double value, String symbol) =>
      '$symbol${value.toStringAsFixed(2)}';

  String _rate(double value) =>
      value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
}
