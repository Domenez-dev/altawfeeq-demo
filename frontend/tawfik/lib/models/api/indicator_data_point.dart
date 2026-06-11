class IndicatorDataPoint {
  final String date;  // "01/05"
  final double value; // 0 → 100

  const IndicatorDataPoint({
    required this.date,
    required this.value,
  });

  factory IndicatorDataPoint.fromJson(Map<String, dynamic> json) {
    return IndicatorDataPoint(
      date: json['date'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'value': value,
  };
}
