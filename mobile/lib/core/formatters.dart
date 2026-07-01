import 'package:intl/intl.dart';

final _priceFmt = NumberFormat.decimalPattern('ar');

String formatPrice(int value, {String currency = 'IQD'}) {
  final unit = currency == 'IQD' ? 'د.ع' : currency;
  return '${_priceFmt.format(value)} $unit';
}

/// صياغة عربية سليمة للمدد: مفرد/مثنى/جمع.
String _plural(int n, String one, String two, String few, String many) {
  if (n == 1) return one;
  if (n == 2) return two;
  if (n >= 3 && n <= 10) return 'قبل $n $few';
  return 'قبل $n $many';
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) {
    return _plural(diff.inMinutes, 'قبل دقيقة', 'قبل دقيقتين', 'دقائق', 'دقيقة');
  }
  if (diff.inHours < 24) {
    return _plural(diff.inHours, 'قبل ساعة', 'قبل ساعتين', 'ساعات', 'ساعة');
  }
  if (diff.inDays < 30) {
    return _plural(diff.inDays, 'أمس', 'قبل يومين', 'أيام', 'يوماً');
  }
  final months = (diff.inDays / 30).floor();
  return _plural(months, 'قبل شهر', 'قبل شهرين', 'أشهر', 'شهراً');
}

/// وقت قصير للرسائل داخل المحادثة (٠٩:٤٥).
String shortTime(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());

/// تاريخ مقروء لفواصل الأيام في المحادثة.
String chatDate(DateTime dt) {
  final now = DateTime.now();
  final d = dt.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  if (day == today) return 'اليوم';
  if (day == today.subtract(const Duration(days: 1))) return 'أمس';
  return DateFormat('d MMMM yyyy', 'ar').format(d);
}
