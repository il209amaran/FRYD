import 'package:flutter_test/flutter_test.dart';
import 'package:fryd/core/services/tax_calculator.dart';
import 'package:fryd/models/business_settings.dart';

void main() {
  test('disabled tax leaves subtotal unchanged', () {
    final result = TaxCalculator.calculate(500, _settings(enabled: false));
    expect(result.taxAmount, 0);
    expect(result.total, 500);
  });

  test('exclusive tax is added to the subtotal', () {
    final result = TaxCalculator.calculate(
      500,
      _settings(enabled: true, rate: 5),
    );
    expect(result.taxAmount, 25);
    expect(result.total, 525);
  });

  test('inclusive tax extracts tax without increasing total', () {
    final result = TaxCalculator.calculate(
      525,
      _settings(enabled: true, rate: 5, inclusive: true),
    );
    expect(result.taxAmount, 25);
    expect(result.total, 525);
  });
}

BusinessSettings _settings({
  required bool enabled,
  double rate = 0,
  bool inclusive = false,
}) => BusinessSettings(
  businessName: 'Test',
  businessType: 'Restaurant',
  address: '',
  phone: '',
  email: '',
  country: 'India',
  currencyCode: 'INR',
  taxRegistrationNumber: '',
  taxEnabled: enabled,
  taxName: 'GST',
  taxRate: rate,
  taxInclusive: inclusive,
  setupCompleted: true,
);
