class AlarmRecord {
  final String time;
  final String deviceId;
  final String sensorType;
  final String paramName;
  final String level;
  final double? value;
  final double? threshold;

  const AlarmRecord({
    required this.time,
    required this.deviceId,
    required this.sensorType,
    required this.paramName,
    required this.level,
    this.value,
    this.threshold,
  });

  factory AlarmRecord.fromJson(Map<String, dynamic> json) {
    return AlarmRecord(
      time: json['time'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      sensorType: json['sensor_type'] as String? ?? '',
      paramName: json['param_name'] as String? ?? '',
      level: json['level'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble(),
      threshold: (json['threshold'] as num?)?.toDouble(),
    );
  }
}

class AlarmCount {
  final int warning;
  final int alarm;
  final int total;

  const AlarmCount({
    required this.warning,
    required this.alarm,
    required this.total,
  });

  factory AlarmCount.fromJson(Map<String, dynamic> json) {
    return AlarmCount(
      warning: (json['warning'] as num?)?.toInt() ?? 0,
      alarm: (json['alarm'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  static const AlarmCount zero = AlarmCount(warning: 0, alarm: 0, total: 0);
}
