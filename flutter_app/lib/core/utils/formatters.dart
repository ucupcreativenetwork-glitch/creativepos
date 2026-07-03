import 'package:intl/intl.dart';

abstract final class Formatters {
  static final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String currency(num value) => _currency.format(value);

  static String compact(num value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}rb';
    }
    return value.toString();
  }

  static String dateTime(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(value);
  }
}