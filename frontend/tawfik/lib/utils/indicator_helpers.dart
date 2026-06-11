import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Color statusColor(String status) {
  switch (status) {
    case 'جيد':
      return AppTheme.success;
    case 'متوسط':
      return AppTheme.warning;
    default:
      return AppTheme.error; // ضعيف
  }
}

IconData indicatorIcon(String name) {
  if (name.contains('الطبقة') || name.contains('الاضطراب')) {
    return Icons.bar_chart_rounded;
  }
  return Icons.graphic_eq_rounded;
}

const List<String> kIndicatorNames = [
  'شدة الصوت',
  'المدة',
  'الطبقة الصوتية',
  'الاضطراب (Jitter)',
];
