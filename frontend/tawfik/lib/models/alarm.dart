class Alarm {
  final int? id;
  final int watchId;
  final String medicineName;
  final String time; // Format: HH:mm
  final bool enabled;

  Alarm({
    this.id,
    required this.watchId,
    required this.medicineName,
    required this.time,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'watch_id': watchId,
      'medicine_name': medicineName,
      'time': time,
      'enabled': enabled ? 1 : 0,
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'] as int?,
      watchId: map['watch_id'] as int,
      medicineName: map['medicine_name'] as String,
      time: map['time'] as String,
      enabled: (map['enabled'] as int) == 1,
    );
  }

  Alarm copyWith({
    int? id,
    int? watchId,
    String? medicineName,
    String? time,
    bool? enabled,
  }) {
    return Alarm(
      id: id ?? this.id,
      watchId: watchId ?? this.watchId,
      medicineName: medicineName ?? this.medicineName,
      time: time ?? this.time,
      enabled: enabled ?? this.enabled,
    );
  }
}
