import '../api/api.dart';
import '../api/index.dart';
import '../models/alarm_model.dart';
import '../providers/hopper_threshold_provider.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final ApiClient _httpClient = ApiClient();

  Future<bool> syncThresholds(HopperThresholdProvider config) async {
    try {
      await _httpClient.put(Api.alarmThresholds, body: _buildSyncMap(config));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> fetchThresholds(HopperThresholdProvider config) async {
    try {
      final data = await _httpClient.get(Api.alarmThresholds);
      if (data == null || data['success'] != true) return false;
      final map = (data['data'] as Map<String, dynamic>?) ?? {};
      config.applyBackendThresholds(map);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<AlarmRecord>> queryAlarms({
    DateTime? start,
    DateTime? end,
    String? level,
    String? paramName,
    List<String>? paramNames,
    int limit = 200,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (start != null) params['start'] = start.toUtc().toIso8601String();
    if (end != null) params['end'] = end.toUtc().toIso8601String();
    if (level != null && level.isNotEmpty) params['level'] = level;
    // paramNames 优先 (多参数一次请求); 否则用单个 paramName
    if (paramNames != null && paramNames.isNotEmpty) {
      params['param_names'] = paramNames.join(',');
    } else if (paramName != null && paramName.isNotEmpty) {
      params['param_name'] = paramName;
    }

    try {
      final data = await _httpClient.get(Api.alarmRecords, params: params);
      if (data == null || data['success'] != true) return [];
      final list = (data['data']?['records'] as List?) ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(AlarmRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<AlarmCount> getAlarmCount({int hours = 24}) async {
    try {
      final data = await _httpClient.get(
        Api.alarmCount,
        params: {'hours': hours.toString()},
      );
      if (data == null || data['success'] != true) return AlarmCount.zero;
      return AlarmCount.fromJson(data['data'] as Map<String, dynamic>);
    } catch (_) {
      return AlarmCount.zero;
    }
  }

  Map<String, dynamic> _buildSyncMap(HopperThresholdProvider config) {
    Map<String, dynamic> entry(ThresholdConfig threshold) => {
          'warning_max': threshold.normalMax,
          'alarm_max': threshold.warningMax,
          'enabled': true,
        };

    return {
      'pm10': entry(config.pm10Config),
      'temperature': entry(config.temperatureConfig),
      'voltage_a': entry(config.voltageAConfig),
      'voltage_b': entry(config.voltageBConfig),
      'voltage_c': entry(config.voltageCConfig),
      'current_a': entry(config.currentAConfig),
      'current_b': entry(config.currentBConfig),
      'current_c': entry(config.currentCConfig),
      'power': entry(config.powerConfig),
      'speed_x': entry(config.speedXConfig),
      'speed_y': entry(config.speedYConfig),
      'speed_z': entry(config.speedZConfig),
      'displacement_x': entry(config.displacementXConfig),
      'displacement_y': entry(config.displacementYConfig),
      'displacement_z': entry(config.displacementZConfig),
      'freq_x': entry(config.freqXConfig),
      'freq_y': entry(config.freqYConfig),
      'freq_z': entry(config.freqZConfig),
    };
  }
}
