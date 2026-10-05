import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _integerFormatter = NumberFormat('#,##,###', 'en_US');
  static final NumberFormat _decimalFormatter = NumberFormat('#,##,###.00', 'en_US');

  /// Formats amount into Bangladeshi Taka format (e.g. ৳15,000 or ৳612.50)
  static String format(double amount, {bool showDecimals = false}) {
    final absAmount = amount.abs();
    final formatted = (showDecimals || (absAmount % 1 != 0))
        ? _decimalFormatter.format(absAmount)
        : _integerFormatter.format(absAmount);
    
    final sign = amount < 0 ? '-' : '';
    return '$sign৳$formatted';
  }

  /// Parses text input safely into double
  static double parse(String input) {
    final cleaned = input.replaceAll('৳', '').replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
}
