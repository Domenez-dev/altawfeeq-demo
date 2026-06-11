import 'indicator_result.dart';

class HomeData {
  final String userName;
  final double todayProgress;       // 0.0 → 1.0
  final int completedIndicators;
  final int totalIndicators;
  final List<IndicatorResult> indicators;

  const HomeData({
    required this.userName,
    required this.todayProgress,
    required this.completedIndicators,
    required this.totalIndicators,
    required this.indicators,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      userName: json['user_name'] as String,
      todayProgress: (json['today_progress'] as num).toDouble(),
      completedIndicators: json['completed_indicators'] as int,
      totalIndicators: json['total_indicators'] as int,
      indicators: (json['indicators'] as List<dynamic>)
          .map((e) => IndicatorResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_name': userName,
    'today_progress': todayProgress,
    'completed_indicators': completedIndicators,
    'total_indicators': totalIndicators,
    'indicators': indicators.map((e) => e.toJson()).toList(),
  };
}
