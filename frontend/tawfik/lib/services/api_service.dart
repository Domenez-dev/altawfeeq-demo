import 'package:dio/dio.dart';
import '../models/api/models.dart';

/// خطأ يُرفع عند فشل تحليل التسجيل الصوتي في الخادم.
///
/// يحمل الرسالة العربية القادمة من الـ backend ({detail, code}) حتى تستطيع
/// الواجهة عرضها للمستخدم مباشرةً (مثلاً: "التسجيل قصير جداً").
class AnalysisException implements Exception {
  final String message;
  final String? code;
  const AnalysisException(this.message, [this.code]);

  @override
  String toString() => 'AnalysisException($code): $message';
}

class ApiService {
  /// عنوان الـ backend. الافتراضي الآن هو خادم الإنتاج البعيد، وقابل للضبط
  /// وقت التشغيل عبر --dart-define دون تعديل الكود:
  ///   - للتطوير المحلي مرّر عنوان localhost، مثلاً:
  ///       flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
  ///   - أو عنوان الـ LAN لهاتف حقيقي على نفس الشبكة.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://209.38.246.75:8000/api',
  );

  final Dio _dio;

  // نموذج أوّلي بمستخدم واحد: الخادم مفتوح ولا يتطلّب مصادقة، لذا لا حاجة
  // لتسجيل دخول أو توكن — نُجري النداءات مباشرةً.
  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  // ─── Home ─────────────────────────────────────────────────────────────────

  Future<HomeData> getHomeData() async {
    final res = await _dio.get('/home');
    return HomeData.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Sessions ─────────────────────────────────────────────────────────────

  Future<List<Session>> getSessions() async {
    final res = await _dio.get('/sessions');
    return (res.data as List<dynamic>)
        .map((e) => Session.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Delete sessions ──────────────────────────────────────────────────────

  Future<void> deleteSession(int id) async {
    await _dio.delete('/sessions/$id');
  }

  /// حذف عدة جلسات دفعةً واحدة. يُعيد عدد الجلسات المحذوفة فعلاً.
  Future<int> deleteSessions(List<int> ids) async {
    final res = await _dio.post('/sessions/delete', data: {'ids': ids});
    return (res.data['deleted'] as num).toInt();
  }

  // ─── Submit session (enregistrement terminé) ──────────────────────────────

  Future<SessionResult> submitSession(String indicatorName, int durationSeconds) async {
    final res = await _dio.post('/sessions', data: {
      'indicator_name': indicatorName,
      'duration_seconds': durationSeconds,
    });
    return SessionResult.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Analyze a real recording ─────────────────────────────────────────────

  static const _monthsAr = {
    1: 'جانفي', 2: 'فيفري', 3: 'مارس', 4: 'أفريل', 5: 'ماي', 6: 'جوان',
    7: 'جويلية', 8: 'أوت', 9: 'سبتمبر', 10: 'أكتوبر', 11: 'نوفمبر', 12: 'ديسمبر',
  };

  String _statusFor(double score) =>
      score >= 70.0 ? 'جيد' : score >= 40.0 ? 'متوسط' : 'ضعيف';

  /// يرفع ملف التسجيل (WAV) إلى نقطة /analysis/analyze التي تشغّل تحليل Praat
  /// الحقيقي، تحفظ الجلسة في قاعدة البيانات، وتُرجع المؤشرات الصوتية الفعلية.
  ///
  /// تُعيد [SessionResult] مبنية من النتيجة السريرية ليعرضها شاشة النتيجة، وبما
  /// أن الخادم يحفظ الجلسة فإنها تظهر تلقائياً في التحليل اليومي/الأسبوعي والسجل.
  ///
  /// ترفع [AnalysisException] برسالة عربية إذا رفض الخادم التسجيل (قصير جداً،
  /// جودة ضعيفة، صيغة غير مدعومة...).
  Future<SessionResult> analyzeRecording(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'recording.wav',
        contentType: DioMediaType('audio', 'wav'),
      ),
    });

    try {
      final res = await _dio.post(
        '/analysis/analyze',
        data: formData,
        // التحليل أبطأ من بقية الطلبات (ffmpeg + Praat)، نمنحه مهلة أطول.
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      final json = res.data as Map<String, dynamic>;
      double score(String key) => (json[key] as num).toDouble();

      final recordedAt = DateTime.parse(json['recorded_at'] as String).toLocal();
      final month = _monthsAr[recordedAt.month] ?? '';
      final date = '${recordedAt.year} - $month ${recordedAt.day.toString().padLeft(2, '0')}';

      final indicators = [
        ('شدة الصوت', score('intensity_score')),
        ('المدة', score('duration_score')),
        ('الطبقة الصوتية', score('f0_score')),
        ('الاضطراب (Jitter)', score('jitter_score')),
      ].map((e) => IndicatorResult(
            name: e.$1,
            percent: e.$2 / 100.0,
            status: _statusFor(e.$2),
          )).toList();

      return SessionResult(
        sessionId: json['id'] as int,
        date: date,
        overallPercent: score('overall_score') / 100.0,
        indicators: indicators,
      );
    } on DioException catch (e) {
      // الخادم يُرجع {detail, code} على الأخطاء 422؛ نمررها كرسالة عربية.
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        throw AnalysisException(data['detail'] as String, data['code'] as String?);
      }
      throw const AnalysisException('تعذّر الاتصال بالخادم لتحليل التسجيل');
    }
  }

  // ─── Indicator detail ─────────────────────────────────────────────────────

  Future<IndicatorDetail> getIndicatorDetail(String indicatorName) async {
    final res = await _dio.get('/analysis/indicators/$indicatorName');
    return IndicatorDetail.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Reports ──────────────────────────────────────────────────────────────

  Future<WeeklyReport> getReport({String period = 'weekly'}) async {
    final res = await _dio.get('/reports', queryParameters: {'period': period});
    return WeeklyReport.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  Future<UserProfile> getUserProfile() async {
    final res = await _dio.get('/profile');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }
}
