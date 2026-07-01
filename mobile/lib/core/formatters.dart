import 'package:intl/intl.dart';

final _priceFmt = NumberFormat.decimalPattern('ar');

String formatPrice(int value, {String currency = 'IQD'}) {
  final unit = currency == 'IQD' ? 'د.ع' : currency;
  return '${_priceFmt.format(value)} $unit';
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'قبل ${diff.inHours} ساعة';
  if (diff.inDays < 30) return 'قبل ${diff.inDays} يوم';
  return 'قبل ${(diff.inDays / 30).floor()} شهر';
}
