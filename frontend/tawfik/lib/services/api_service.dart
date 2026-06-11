import 'package:dio/dio.dart';
import '../models/api/models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';

  final Dio _dio;

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
    // TODO: remplacer par → final res = await _dio.get('/home'); return HomeData.fromJson(res.data);
    await Future.delayed(const Duration(milliseconds: 600));
    return HomeData.fromJson({
      'user_name': 'محمد',
      'today_progress': 0.75,
      'completed_indicators': 3,
      'total_indicators': 4,
      'indicators': [
        {'name': 'الصوت', 'percent': 0.75, 'status': 'جيد'},
        {'name': 'المدة', 'percent': 0.60, 'status': 'متوسط'},
        {'name': 'الطبقة الصوتية', 'percent': 0.45, 'status': 'ضعيف'},
        {'name': 'الاضطراب (Jitter)', 'percent': 0.30, 'status': 'ضعيف'},
      ],
    });
  }

  // ─── Sessions ─────────────────────────────────────────────────────────────

  Future<List<Session>> getSessions() async {
    // TODO: remplacer par → final res = await _dio.get('/sessions'); return (res.data as List).map(Session.fromJson).toList();
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      Session.fromJson({'id': 7, 'title': 'جلسة 07', 'date': '2025 - 08 ماي', 'time': '16:30', 'overall_percent': 0.75}),
      Session.fromJson({'id': 6, 'title': 'جلسة 06', 'date': '2025 - 06 ماي', 'time': '18:10', 'overall_percent': 0.60}),
      Session.fromJson({'id': 5, 'title': 'جلسة 05', 'date': '2025 - 06 ماي', 'time': '17:45', 'overall_percent': 0.45}),
      Session.fromJson({'id': 4, 'title': 'جلسة 04', 'date': '2025 - 04 ماي', 'time': '16:20', 'overall_percent': 0.30}),
      Session.fromJson({'id': 3, 'title': 'جلسة 03', 'date': '2025 - 03 ماي', 'time': '15:35', 'overall_percent': 0.55}),
    ];
  }

  // ─── Submit session (enregistrement terminé) ──────────────────────────────

  Future<SessionResult> submitSession(String indicatorName, int durationSeconds) async {
    // TODO: remplacer par → final res = await _dio.post('/sessions', data: {...}); return SessionResult.fromJson(res.data);
    await Future.delayed(const Duration(milliseconds: 800));
    return SessionResult.fromJson({
      'session_id': 8,
      'date': '2025 - ماي 05',
      'overall_percent': 0.75,
      'indicators': [
        {'name': 'شدة الصوت', 'percent': 0.75, 'status': 'جيد'},
        {'name': 'المدة', 'percent': 0.60, 'status': 'متوسط'},
        {'name': 'الطبقة الصوتية (FO)', 'percent': 0.45, 'status': 'ضعيف'},
        {'name': 'الاضطراب (Jitter)', 'percent': 0.30, 'status': 'ضعيف'},
      ],
    });
  }

  // ─── Indicator detail ─────────────────────────────────────────────────────

  Future<IndicatorDetail> getIndicatorDetail(String indicatorName) async {
    // TODO: remplacer par → final res = await _dio.get('/indicators/$indicatorName'); return IndicatorDetail.fromJson(res.data);
    await Future.delayed(const Duration(milliseconds: 500));
    return IndicatorDetail.fromJson({
      'name': indicatorName,
      'history': [
        {'date': '01/05', 'value': 45.0},
        {'date': '03/05', 'value': 60.0},
        {'date': '05/05', 'value': 55.0},
        {'date': '07/05', 'value': 75.0},
      ],
      'analysis': 'تحسن ملحوظ في شدة الصوت. استمر في التمارين',
      'natural_range': '60% - 90%',
      'results': 'حاول التحدث بصوت ثابت وواضح',
    });
  }

  // ─── Reports ──────────────────────────────────────────────────────────────

  Future<WeeklyReport> getReport({String period = 'weekly'}) async {
    // TODO: remplacer par → final res = await _dio.get('/reports', queryParameters: {'period': period}); return WeeklyReport.fromJson(res.data);
    await Future.delayed(const Duration(milliseconds: 600));
    return WeeklyReport.fromJson({
      'average_percent': 0.62,
      'compared_to_last_week': 0.15,
      'chart_data': [40.0, 55.0, 45.0, 70.0, 60.0, 80.0, 62.0],
      'good_count': 1,
      'average_count': 1,
      'weak_count': 2,
      'sessions_count': 4,
    });
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  Future<UserProfile> getUserProfile() async {
    // TODO: remplacer par → final res = await _dio.get('/profile'); return UserProfile.fromJson(res.data);
    await Future.delayed(const Duration(milliseconds: 400));
    return UserProfile.fromJson({
      'id': 1,
      'name': 'محمد',
      'email': 'mohamed@mail.com',
      'therapeutic_goal': 'تحسين وضوح الصوت',
    });
  }
}
