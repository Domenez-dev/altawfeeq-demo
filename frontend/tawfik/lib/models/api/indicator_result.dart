class IndicatorResult {
  final String name;
  final double percent; // 0.0 → 1.0
  final String status;  // "جيد" | "متوسط" | "ضعيف"

  const IndicatorResult({
    required this.name,
    required this.percent,
    required this.status,
  });

  factory IndicatorResult.fromJson(Map<String, dynamic> json) {
    return IndicatorResult(
      name: json['name'] as String,
      percent: (json['percent'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'percent': percent,
    'status': status,
  };
}
