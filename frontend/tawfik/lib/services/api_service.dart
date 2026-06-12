import 'package:dio/dio.dart';
import '../models/api/models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';

  final Dio _dio;
  String? _token;

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // If we are not logging in, and we don't have a token, do auto-login
          if (options.path != '/auth/login' && _token == null) {
            await _loginWithSeedCredentials();
          }
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<void> _loginWithSeedCredentials() async {
    try {
      // Create a separate Dio instance to avoid recursive calls in request interceptor
      final loginDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final res = await loginDio.post('/auth/login', data: {
        'email': 'mohamed@altawfeeq.dz',
        'password': 'password123',
      });
      _token = res.data['access_token'] as String;
    } catch (e) {
      print('Auto-login with seed credentials failed: $e');
    }
  }

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

  // ─── Submit session (enregistrement terminé) ──────────────────────────────

  Future<SessionResult> submitSession(String indicatorName, int durationSeconds) async {
    final res = await _dio.post('/sessions', data: {
      'indicator_name': indicatorName,
      'duration_seconds': durationSeconds,
    });
    return SessionResult.fromJson(res.data as Map<String, dynamic>);
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
