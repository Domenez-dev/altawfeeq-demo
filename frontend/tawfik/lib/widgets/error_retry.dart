import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// عرض موحّد لحالات الخطأ مع زر "إعادة المحاولة".
///
/// يُستخدم في الشاشات التي تجلب بيانات من الخادم: عند أي مشكلة اتصال
/// (4xx أو 5xx أو رفض الاتصال) يضغط المستخدم الزر لإعادة المحاولة بدل إعادة
/// تشغيل التطبيق بالكامل.
class ErrorRetryView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorRetryView({super.key, required this.error, required this.onRetry});

  /// رسالة عربية مناسبة لنوع الخطأ.
  String get _message {
    final e = error;
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'انتهت مهلة الاتصال بالخادم';
        case DioExceptionType.connectionError:
          return 'تعذّر الاتصال بالخادم. تأكد من تشغيل الخادم والشبكة.';
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode ?? 0;
          // حاول إظهار رسالة الخادم العربية إن وُجدت ({detail, code}).
          final data = e.response?.data;
          if (data is Map && data['detail'] is String) {
            return data['detail'] as String;
          }
          if (code >= 500) return 'خطأ في الخادم ($code)';
          return 'تعذّر تنفيذ الطلب ($code)';
        default:
          return 'حدث خطأ في الاتصال';
      }
    }
    return 'حدث خطأ غير متوقع';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, color: AppTheme.error, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('إعادة المحاولة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
