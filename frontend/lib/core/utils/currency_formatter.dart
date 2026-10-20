import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static String format(double amount, {String currency = 'INR', bool includeSymbol = true}) {
    final symbol = includeSymbol ? (AppConstants.currencySymbols[currency] ?? '$currency ') : '';

    if (currency == 'INR') {
      // Indian numbering format (e.g., 1,50,000.00)
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: symbol,
        decimalDigits: 2,
      );
      return formatter.format(amount);
    } else {
      // Standard international format
      final formatter = NumberFormat.currency(
        symbol: symbol,
        decimalDigits: 2,
      );
      return formatter.format(amount);
    }
  }

  static String formatCompact(double amount, {String currency = 'INR'}) {
    final symbol = AppConstants.currencySymbols[currency] ?? '';
    if (amount >= 10000000) {
      return '$symbol${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }
}
