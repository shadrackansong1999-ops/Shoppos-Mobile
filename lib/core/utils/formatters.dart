import 'package:intl/intl.dart';

/// Kept intentionally simple (a symbol + 2dp) rather than locale-detected,
/// since the currency is a shop setting (defaults GHS, matching the
/// desktop app), not the phone's locale.
class Money {
  static String currencySymbol = 'GHS';

  static String format(num value) {
    final f = NumberFormat.currency(symbol: '', decimalDigits: 2);
    return '$currencySymbol ${f.format(value)}';
  }
}

String formatDate(DateTime dt) => DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
String formatDateShort(DateTime dt) => DateFormat('dd MMM yyyy').format(dt.toLocal());
