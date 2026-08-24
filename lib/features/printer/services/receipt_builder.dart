import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../core/utils/date_time_formatter.dart';
import '../../../models/order.dart';
import '../../../models/order_item.dart';

class ReceiptBuilder {
  Future<List<int>> build({
    required RestaurantOrder order,
    required List<OrderItem> items,
    String? customerName,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];
    bytes.addAll(
      generator.text(
        'FRYD',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        'TAKEOUT by AKILA',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(generator.text('Order: ${order.orderNumber}'));
    final trimmedCustomerName = customerName?.trim();
    if (trimmedCustomerName != null && trimmedCustomerName.isNotEmpty) {
      bytes.addAll(generator.text('Customer: $trimmedCustomerName'));
    }
    bytes.addAll(generator.text('Date : ${formatDate(order.createdAt)}'));
    bytes.addAll(generator.text('Time : ${formatTime(order.createdAt)}'));
    bytes.addAll(generator.hr(ch: '-'));

    for (final item in items) {
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
          : '  ${item.quantity} x ${_money(item.unitPrice)}';
      bytes.addAll(
        generator.row([
          PosColumn(text: details, width: 8),
          PosColumn(
            text: item.isComplementary ? 'FREE' : _money(item.total),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
      bytes.addAll(generator.feed(1));
    }

    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(_totalRow(generator, 'Subtotal', order.subtotal));
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(_totalRow(generator, 'TOTAL', order.total, bold: true));
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(generator.feed(1));
    bytes.addAll(
      generator.text(
        'Thank You!',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(
      generator.text(
        'Visit Again :)',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
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
    double value, {
    bool bold = false,
  }) => generator.row([
    PosColumn(
      text: label,
      width: 7,
      styles: PosStyles(bold: bold),
    ),
    PosColumn(
      text: _money(value),
      width: 5,
      styles: PosStyles(align: PosAlign.right, bold: bold),
    ),
  ]);

  String _money(double value) => value.toStringAsFixed(2);
}
