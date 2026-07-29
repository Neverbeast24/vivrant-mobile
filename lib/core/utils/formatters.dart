import 'package:intl/intl.dart';

String formatCurrency(num amount, {String symbol = '₱'}) {
  final formatted = NumberFormat('#,##0.##').format(amount);
  return '$symbol$formatted';
}

String formatDate(DateTime date, {String pattern = 'MMM d, y'}) {
  return DateFormat(pattern).format(date);
}

String formatShortDate(DateTime date) => formatDate(date, pattern: 'MMM d');
