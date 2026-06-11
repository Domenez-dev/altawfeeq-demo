class WeeklyReport {
  final double averagePercent;      // 0.0 → 1.0
  final double comparedToLastWeek;  // ex: 0.15 = +15%
  final List<double> chartData;     // valeurs pour le graphique linéaire
  final int goodCount;
  final int averageCount;
  final int weakCount;
  final int sessionsCount;

  const WeeklyReport({
    required this.averagePercent,
    required this.comparedToLastWeek,
    required this.chartData,
    required this.goodCount,
    required this.averageCount,
    required this.weakCount,
    required this.sessionsCount,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      averagePercent: (json['average_percent'] as num).toDouble(),
      comparedToLastWeek: (json['compared_to_last_week'] as num).toDouble(),
      chartData: (json['chart_data'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      goodCount: json['good_count'] as int,
      averageCount: json['average_count'] as int,
      weakCount: json['weak_count'] as int,
      sessionsCount: json['sessions_count'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'average_percent': averagePercent,
    'compared_to_last_week': comparedToLastWeek,
    'chart_data': chartData,
    'good_count': goodCount,
    'average_count': averageCount,
    'weak_count': weakCount,
    'sessions_count': sessionsCount,
  };
}
