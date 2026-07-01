import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souqna/core/theme.dart';

void main() {
  test('dark theme builds with SxColors extension', () {
    final theme = AppTheme.dark();
    expect(theme.extension<SxColors>(), isNotNull);
    expect(theme.brightness, Brightness.dark);
  });

  test('light theme builds with SxColors extension', () {
    final theme = AppTheme.light();
    expect(theme.extension<SxColors>(), isNotNull);
    expect(theme.brightness, Brightness.light);
  });

  test('both themes use the Tajawal font', () {
    expect(AppTheme.dark().textTheme.bodyMedium?.fontFamily, 'Tajawal');
    expect(AppTheme.light().textTheme.bodyMedium?.fontFamily, 'Tajawal');
  });
}
