import 'package:intl/intl.dart';
import '../models/currency.dart';

final _monthFmt      = DateFormat('MMM yyyy');
final _shortMonthFmt = DateFormat('MMM');
final _dateFmt       = DateFormat('MMM d, yyyy');
final _dayFmt        = DateFormat('EEE, MMM d');

//String formatCurrency(double amount, [AppCurrency? currency]) {
//  final sym = currency?.symbol ?? '\$';
//  return '$sym${amount.toStringAsFixed(2)}';
//}

String formatCurrency(double amount, AppCurrency currency) {
  final formatter = NumberFormat.currency(
    symbol: '${currency.symbol} ',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

String formatMonth(DateTime dt)      => _monthFmt.format(dt);
String formatShortMonth(DateTime dt) => _shortMonthFmt.format(dt);
String formatDate(DateTime dt)       => _dateFmt.format(dt);
String formatDayDate(DateTime dt)    => _dayFmt.format(dt);

String relativeDate(DateTime dt) {
  final now  = DateTime.now();
  final diff = DateTime(now.year, now.month, now.day)
      .difference(DateTime(dt.year, dt.month, dt.day)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7)  return '$diff days ago';
  return formatDate(dt);
}
