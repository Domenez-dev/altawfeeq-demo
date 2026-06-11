import 'indicator_data_point.dart';

class IndicatorDetail {
  final String name;                       // "شدة الصوت"
  final List<IndicatorDataPoint> history;  // points du graphique
  final String analysis;                   // texte d'analyse
  final String naturalRange;              // "60% - 90%"
  final String results;                   // texte des résultats

  const IndicatorDetail({
    required this.name,
    required this.history,
    required this.analysis,
    required this.naturalRange,
    required this.results,
  });

  factory IndicatorDetail.fromJson(Map<String, dynamic> json) {
    return IndicatorDetail(
      name: json['name'] as String,
      history: (json['history'] as List<dynamic>)
          .map((e) => IndicatorDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      analysis: json['analysis'] as String,
      naturalRange: json['natural_range'] as String,
      results: json['results'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'history': history.map((e) => e.toJson()).toList(),
    'analysis': analysis,
    'natural_range': naturalRange,
    'results': results,
  };
}
