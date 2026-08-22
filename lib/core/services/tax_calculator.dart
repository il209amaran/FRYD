import '../../models/business_settings.dart';

class TaxCalculation {
  const TaxCalculation({
    required this.subtotal,
    required this.taxName,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
  });

  final double subtotal;
  final String taxName;
  final double taxRate;
  final double taxAmount;
  final double total;
}

abstract final class TaxCalculator {
  static TaxCalculation calculate(
    double paidSubtotal,
    BusinessSettings settings,
  ) {
    if (!settings.taxEnabled || settings.taxRate <= 0) {
      return TaxCalculation(
        subtotal: paidSubtotal,
        taxName: settings.taxName,
        taxRate: 0,
        taxAmount: 0,
        total: paidSubtotal,
      );
    }
    final rate = settings.taxRate;
    final tax = settings.taxInclusive
        ? paidSubtotal * rate / (100 + rate)
        : paidSubtotal * rate / 100;
    return TaxCalculation(
      subtotal: paidSubtotal,
      taxName: settings.taxName,
      taxRate: rate,
      taxAmount: tax,
      total: settings.taxInclusive ? paidSubtotal : paidSubtotal + tax,
    );
  }
}
