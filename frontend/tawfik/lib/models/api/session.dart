import 'indicator_result.dart';

class Session {
  final int id;
  final String title;          // "جلسة 07"
  final String date;           // "2025 - 08 ماي"
  final String time;           // "16:30"
  final double overallPercent; // 0.0 → 1.0
  final List<IndicatorResult>? indicators; // null dans la liste, rempli dans le détail

  const Session({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.overallPercent,
    this.indicators,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as int,
      title: json['title'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      overallPercent: (json['overall_percent'] as num).toDouble(),
      indicators: (json['indicators'] as List<dynamic>?)
          ?.map((e) => IndicatorResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'time': time,
    'overall_percent': overallPercent,
    'indicators': indicators?.map((e) => e.toJson()).toList(),
  };
}
