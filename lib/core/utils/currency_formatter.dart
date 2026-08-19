import '../constants/app_constants.dart';

String formatCurrency(double value) {
  final decimals = value == value.roundToDouble() ? 0 : 2;
  return '${AppConstants.currencySymbol}${value.toStringAsFixed(decimals)}';
}
