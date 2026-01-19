import 'dart:async';
import 'package:flutter/material.dart';
import '../api/api.dart';
import '../api/index.dart';

/// 历史数据服务
/// 用于查询后端历史数据API，支持动态聚合间隔
class HistoryDataService {
  static final HistoryDataService _instance = HistoryDataService._internal();
  factory HistoryDataService() => _instance;
  HistoryDataService._internal();

  // ============================================================
  // 时间格式化辅助方法
  // ============================================================

  /// 将DateTime转换为本地时间字符串（不转UTC，因为后端存储的是北京时间）
  static String _formatLocalTime(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}T'
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // 设备ID映射常量
  // ============================================================

  /// 回转窑设备ID映射（1-9号窑对应device_id）
  static const Map<int, String> hopperDeviceIds = {
    1: 'short_hopper_1',
    2: 'short_hopper_2',
    3: 'short_hopper_3',
    4: 'short_hopper_4',
    // 5, 6 skipped
    7: 'long_hopper_1',
    8: 'long_hopper_2',
    9: 'long_hopper_3',
  };

  // ============================================================
  // 动态聚合间隔计算
  // ============================================================

  /// 目标数据点数（保持图表显示效果一致）
  static const int _targetPoints = 80;

  /// 可接受的数据点范围
  static const int _minPoints = 40;
  static const int _maxPoints = 150;

  /// 有效的聚合间隔选项（秒）
  static const List<int> _validIntervals = [
    5, 10, 15, 30, 60, 120, 180, 300, 600, 900, 
    1800, 3600, 7200, 14400, 21600, 43200, 86400, 
    172800, 259200, 604800, 1209600, 2592000
  ];

  static String calculateAggregateInterval(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final totalSeconds = duration.inSeconds;

    if (totalSeconds <= 0) return '5s';

    final idealIntervalSeconds = totalSeconds / _targetPoints;
    int bestInterval = _validIntervals[0];
    double minDiff = double.infinity;

    for (final interval in _validIntervals) {
      final estimatedPoints = totalSeconds / interval;
      if (estimatedPoints >= _minPoints && estimatedPoints <= _maxPoints) {
        final diff = (estimatedPoints - _targetPoints).abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestInterval = interval;
        }
      }
    }

    if (minDiff == double.infinity) {
      minDiff = double.infinity;
      for (final interval in _validIntervals) {
        final diff = (interval - idealIntervalSeconds).abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestInterval = interval;
        }
      }
    }

    return _formatInterval(bestInterval);
  }

  static String _formatInterval(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      return '${seconds ~/ 60}m';
    } else if (seconds < 86400) {
      return '${seconds ~/ 3600}h';
    } else {
      return '${seconds ~/ 86400}d';
    }
  }

  // ============================================================
  // 料仓历史数据查询
  // ============================================================

  /// 查询料仓历史数据
  Future<HistoryDataResult> queryHopperHistory({
    required String deviceId,
    required DateTime start,
    required DateTime end,
    String? moduleType,
    List<String>? fields,
  }) async {
    final interval = calculateAggregateInterval(start, end);

    final queryParams = <String, String>{
      'start': _formatLocalTime(start),
      'end': _formatLocalTime(end),
      'interval': interval,
    };

    if (moduleType != null) {
      queryParams['module_type'] = moduleType;
    }
    if (fields != null && fields.isNotEmpty) {
      queryParams['fields'] = fields.join(',');
    }

    final uri = Uri.parse('${Api.baseUrl}${Api.hopperHistory(deviceId)}')
        .replace(queryParameters: queryParams);

    return _fetchHistoryData(uri, deviceId);
  }

  /// 查询料仓温度历史
  Future<HistoryDataResult> queryHopperTemperatureHistory(
      String deviceId, DateTime start, DateTime end) {
    return queryHopperHistory(
      deviceId: deviceId,
      start: start,
      end: end,
      moduleType: 'TemperatureSensor',
      fields: ['temperature'],
    );
  }

  /// 查询料仓称重历史（重量、下料速度）
  Future<HistoryDataResult> queryHopperWeightHistory(
      String deviceId, DateTime start, DateTime end) {
    return queryHopperHistory(
      deviceId: deviceId,
      start: start,
      end: end,
      moduleType: 'WeighSensor',
      fields: ['weight', 'feed_rate'],
    );
  }

  /// 查询料仓能耗历史 (ImpEp - 累积电能, Pt - 有功功率)
  Future<HistoryDataResult> queryHopperEnergyHistory(
      String deviceId, DateTime start, DateTime end) {
    return queryHopperHistory(
      deviceId: deviceId,
      start: start,
      end: end,
      moduleType: 'ElectricityMeter',
      fields: ['ImpEp', 'Pt'],
    );
  }

  // ============================================================
  // 内部方法
  // ============================================================

  Future<HistoryDataResult> _fetchHistoryData(Uri uri, String deviceId) async {
    final client = ApiClient();

    try {
      final params = <String, String>{};
      uri.queryParameters.forEach((key, value) {
        params[key] = value;
      });

      final json = await client.get(uri.path, params: params.isNotEmpty ? params : null);

      if (json['success'] == true) {
        final data = json['data'];
        final dataList = data['data'] as List<dynamic>? ?? [];

        return HistoryDataResult(
          success: true,
          deviceId: deviceId,
          timeRange: TimeRange(
            start: DateTime.parse(data['time_range']['start']).toLocal(),
            end: DateTime.parse(data['time_range']['end']).toLocal(),
          ),
          interval: data['interval'] ?? '5m',
          dataPoints: dataList.map((e) => HistoryDataPoint.fromJson(e)).toList(),
        );
      } else {
        return HistoryDataResult(
          success: false,
          deviceId: deviceId,
          error: json['error'] ?? '查询失败',
        );
      }
    } catch (e) {
      debugPrint('❌ 历史数据请求失败: $e');
      return HistoryDataResult(
        success: false,
        deviceId: deviceId,
        error: '网络错误: $e',
      );
    }
  }
}

// ============================================================
// 数据模型
// ============================================================

class HistoryDataResult {
  final bool success;
  final String deviceId;
  final TimeRange? timeRange;
  final String? interval;
  final List<HistoryDataPoint>? dataPoints;
  final String? error;

  HistoryDataResult({
    required this.success,
    required this.deviceId,
    this.timeRange,
    this.interval,
    this.dataPoints,
    this.error,
  });

  List<HistoryDataPoint>? get data => dataPoints;
}

class TimeRange {
  final DateTime start;
  final DateTime end;
  TimeRange({required this.start, required this.end});
}

class HistoryDataPoint {
  final DateTime timestamp;
  final Map<String, dynamic> fields;

  HistoryDataPoint({required this.timestamp, required this.fields});

  factory HistoryDataPoint.fromJson(Map<String, dynamic> json) {
    final timeStr = json['time'] as String;
    final time = DateTime.parse(timeStr).toLocal();
    final fields = <String, dynamic>{};
    for (var entry in json.entries) {
      if (entry.key != 'time' && entry.key != 'module_tag' && entry.key != 'module_type') {
        fields[entry.key] = entry.value;
      }
    }
    return HistoryDataPoint(timestamp: time, fields: fields);
  }

  // Common getters
  double get value {
    // If there is only one field, return it.
    if (fields.length == 1) return _getDouble(fields.keys.first) ?? 0;
    // Otherwise try common value fields
    return _getDouble('value') ?? 0;
  }
  
  double get temperature => _getDouble('temperature') ?? 0;
  double get weight => _getDouble('weight') ?? 0;
  double get feedRate => _getDouble('feed_rate') ?? 0;
  double get pt => _getDouble('Pt') ?? 0;
  double get impEp => _getDouble('ImpEp') ?? 0;

  double? _getDouble(String key) {
    final value = fields[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
