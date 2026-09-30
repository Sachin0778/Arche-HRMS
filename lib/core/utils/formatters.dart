import 'package:intl/intl.dart';

/// Formatting helpers shared across the presentation layer.
class Formatters {
  Formatters._();

  static const String currencySymbol = '₹';

  static final NumberFormat _currency =
      NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
  static final NumberFormat _compactCurrency =
      NumberFormat.compactCurrency(symbol: currencySymbol, decimalDigits: 1);
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');

  static String currency(double value) => _currency.format(value);
  static String compactCurrency(double value) => _compactCurrency.format(value);
  static String date(DateTime value) => _date.format(value);
  static String dateTime(DateTime value) => _dateTime.format(value);
  static String monthYear(DateTime value) => _monthYear.format(value);

  /// Returns "Good morning" / "Good afternoon" / "Good evening" for [now].
  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// "Jane Doe" -> "JD"; "Cher" -> "C".
  static String initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}