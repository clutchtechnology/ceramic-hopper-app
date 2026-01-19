/// 投料记录模型
/// 用于存储和展示投料历史数据
class FeedingRecord {
  final DateTime time; // 投料时间
  final double addedWeight; // 实际投料重量 (kg)
  final String deviceId; // 设备ID

  FeedingRecord({
    required this.time,
    required this.addedWeight,
    required this.deviceId,
  });

  factory FeedingRecord.fromJson(Map<String, dynamic> json) {
    return FeedingRecord(
      time: DateTime.parse(json['time']),
      addedWeight: (json['added_weight'] as num).toDouble(),
      deviceId: json['device_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'added_weight': addedWeight,
      'device_id': deviceId,
    };
  }
}
