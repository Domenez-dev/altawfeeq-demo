import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';

/// مفتاح حفظ الوضع الليلي في جدول الإعدادات.
const _kDarkModeKey = 'dark_mode';

/// يدير وضع الثيم (فاتح/ليلي) ويحفظ الاختيار محلياً عبر sqflite.
///
/// عند كل تغيير يُحدّث [AppTheme.applyMode] أولاً (حتى تلتقط الشاشات الألوان
/// الجديدة فوراً) ثم يبثّ الحالة لإعادة بناء الواجهة.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(super.initial) {
    AppTheme.applyMode(state == ThemeMode.dark);
  }

  bool get isDark => state == ThemeMode.dark;

  Future<void> setDark(bool dark) async {
    AppTheme.applyMode(dark);
    state = dark ? ThemeMode.dark : ThemeMode.light;
    await DatabaseHelper.instance.setSetting(_kDarkModeKey, dark ? '1' : '0');
  }
}

/// يُقرأ الوضع المحفوظ من قاعدة البيانات (يُستدعى مرة واحدة في main).
Future<ThemeMode> loadStoredThemeMode() async {
  final stored = await DatabaseHelper.instance.getSetting(_kDarkModeKey);
  return stored == '1' ? ThemeMode.dark : ThemeMode.light;
}

/// يجب تجاوزه في [ProviderScope] بقيمة الوضع المحمّلة من main.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  throw UnimplementedError(
    'themeModeProvider must be overridden in ProviderScope (see main.dart)',
  );
});
