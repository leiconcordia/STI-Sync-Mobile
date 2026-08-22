import 'package:intl/intl.dart';

final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');

/// Formats a number into standard Philippine Peso currency representation: `₱1,000.00`
String formatCurrency(num? amount, {bool showSign = false, bool noSymbol = false}) {
  final val = (amount ?? 0).toDouble();
  final formatted = _currencyFormat.format(val.abs());
  final symbol = noSymbol ? '' : '₱';

  if (val < 0) {
    return '-$symbol$formatted';
  }
  if (showSign && val > 0) {
    return '+$symbol$formatted';
  }
  return '$symbol$formatted';
}
