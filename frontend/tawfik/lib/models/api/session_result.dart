import 'indicator_result.dart';

class SessionResult {
  final int sessionId;
  final String date;
  final double overallPercent;        // 0.0 → 1.0
  final List<IndicatorResult> indicators;

  const SessionResult({
    required this.sessionId,
    required this.date,
    required this.overallPercent,
    required this.indicators,
  });

  factory SessionResult.fromJson(Map<String, dynamic> json) {
    return SessionResult(
      sessionId: json['session_id'] as int,
      date: json['date'] as String,
      overallPercent: (json['overall_percent'] as num).toDouble(),
      indicators: (json['indicators'] as List<dynamic>)
          .map((e) => IndicatorResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'date': date,
    'overall_percent': overallPercent,
    'indicators': indicators.map((e) => e.toJson()).toList(),
  };
}
