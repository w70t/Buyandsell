import 'package:flutter_test/flutter_test.dart';
import 'package:souqna/core/formatters.dart';

void main() {
  test('formatPrice appends the IQD unit', () {
    expect(formatPrice(1000), contains('د.ع'));
  });

  test('timeAgo returns "الآن" for just now', () {
    expect(timeAgo(DateTime.now()), 'الآن');
  });
}
