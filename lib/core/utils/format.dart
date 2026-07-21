import 'package:intl/intl.dart';

/// Indian number/currency formatting — lakh/crore aware.
/// Direct port of src/lib/format.ts.
final NumberFormat _inr = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

final NumberFormat _inrDecimal = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

String formatINR(num? value, {bool decimals = false}) {
  if (value == null || !value.isFinite) return '₹0';
  return (decimals ? _inrDecimal : _inr).format(value);
}

/// Compact Indian: 1 Lakh / 1.5 Crore for big numbers, otherwise full ₹X,XX,XXX
String formatINRCompact(num? value) {
  if (value == null || !value.isFinite) return '₹0';
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 10000000) {
    final v = abs / 10000000;
    return '$sign₹${_trim(v)} Crore';
  }
  if (abs >= 100000) {
    final v = abs / 100000;
    return '$sign₹${_trim(v)} Lakh';
  }
  return formatINR(value);
}

String _trim(double n) {
  final digits = n >= 100 ? 0 : (n >= 10 ? 1 : 2);
  var s = n.toStringAsFixed(digits);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}

/// DD/MM/YYYY
String formatDateIN(String? isoOrDate) {
  if (isoOrDate == null || isoOrDate.isEmpty) return '';
  final d = DateTime.tryParse(isoOrDate);
  if (d == null) return '';
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

String isoDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Today's date in IST as yyyy-mm-dd (matches Asia/Kolkata Intl formatting used in dashboard).
String todayIsoIST() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  return isoDate(now);
}

String addDaysIso(String iso, int days) {
  final parts = iso.split('-').map(int.parse).toList();
  final t = DateTime.utc(parts[0], parts[1], parts[2]).add(Duration(days: days));
  return isoDate(t);
}

int daysBetweenIso(String a, String b) {
  final ap = a.split('-').map(int.parse).toList();
  final bp = b.split('-').map(int.parse).toList();
  final ad = DateTime.utc(ap[0], ap[1], ap[2]);
  final bd = DateTime.utc(bp[0], bp[1], bp[2]);
  return bd.difference(ad).inDays;
}

/// Next occurrence of a day-of-month, on/after [today] (yyyy-mm-dd strings).
String nextDueForDay(int day, String today) {
  final parts = today.split('-').map(int.parse).toList();
  final y = parts[0], m = parts[1];
  final daysInMonth = DateTime(y, m + 1, 0).day;
  final d = day < daysInMonth ? day : daysInMonth;
  final thisMonth = '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  if (thisMonth.compareTo(today) >= 0) return thisMonth;
  final nm = m == 12 ? 1 : m + 1;
  final ny = m == 12 ? y + 1 : y;
  final dim2 = DateTime(ny, nm + 1, 0).day;
  final d2 = day < dim2 ? day : dim2;
  return '$ny-${nm.toString().padLeft(2, '0')}-${d2.toString().padLeft(2, '0')}';
}

String greetingForNow() {
  final istHour = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)).hour;
  if (istHour < 12) return 'Good Morning';
  if (istHour < 17) return 'Good Afternoon';
  return 'Good Evening';
}
