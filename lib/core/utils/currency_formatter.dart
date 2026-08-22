import '../../features/business/data/business_settings_repository.dart';
import '../../models/business_settings.dart';

abstract final class CurrencyFormatter {
  static CurrencyOption _currency = CurrencyOption.forCode('INR');

  static String get symbol => _currency.symbol;

  static Future<void> initialize() async {
    final settings = await BusinessSettingsRepository().get();
    update(settings);
  }

  static void update(BusinessSettings settings) {
    _currency = settings.currency;
  }

  static String format(double value) {
    final decimals = value == value.roundToDouble() ? 0 : 2;
    return '${_currency.symbol}${value.toStringAsFixed(decimals)}';
  }
}

String formatCurrency(double value) => CurrencyFormatter.format(value);
