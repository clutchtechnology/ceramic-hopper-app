import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 实时数据配置 Provider (电炉料仓版)
/// 用于持久化存储 PM10、温度、电表、震动等传感器的阈值参数
///
/// 键值结构:
/// - PM10: hopper_{n}_pm10
/// - 料仓温度: hopper_{n}_temp
/// - 震动(RMS): hopper_{n}_vib_rms
/// - 震动(温度): hopper_{n}_vib_temp
/// - 电表(功率): hopper_{n}_power
/// - 电表(电流): hopper_{n}_current

/// 固定颜色配置
class ThresholdColors {
  static const Color normal = Color(0xFF00ff88); // 绿色 - 正常
  static const Color warning = Color(0xFFffcc00); // 黄色 - 警告
  static const Color alarm = Color(0xFFff3b30); // 红色 - 危险/报警
}

/// 单个设备的阈值配置
class ThresholdConfig {
  final String key; // 设备键值
  final String displayName; // 显示名称
  double normalMax; // 正常上限 (超过此值为警告)
  double warningMax; // 警告上限 (超过此值为报警)

  ThresholdConfig({
    required this.key,
    required this.displayName,
    this.normalMax = 0.0,
    this.warningMax = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'displayName': displayName,
        'normalMax': normalMax,
        'warningMax': warningMax,
      };

  factory ThresholdConfig.fromJson(Map<String, dynamic> json) {
    return ThresholdConfig(
      key: json['key'] as String,
      displayName: json['displayName'] as String,
      normalMax: (json['normalMax'] as num?)?.toDouble() ?? 0.0,
      warningMax: (json['warningMax'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ThresholdConfig copyWith({
    double? normalMax,
    double? warningMax,
  }) {
    return ThresholdConfig(
      key: key,
      displayName: displayName,
      normalMax: normalMax ?? this.normalMax,
      warningMax: warningMax ?? this.warningMax,
    );
  }

  /// 根据数值获取状态颜色
  Color getColor(double value) {
    if (value <= normalMax) {
      return ThresholdColors.normal;
    } else if (value <= warningMax) {
      return ThresholdColors.warning;
    } else {
      return ThresholdColors.alarm;
    }
  }
}

class RealtimeConfigProvider extends ChangeNotifier {
  static const String _storageKey = 'realtime_threshold_config_hopper_v1';
  static const int _hopperCount = 8; // 8个料仓

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // 缓存 Map (Key -> Config)
  final Map<String, ThresholdConfig> _cache = {};

  // ============================================================
  // 配置列表
  // ============================================================

  // 1. PM10 传感器配置
  final List<ThresholdConfig> pm10Configs = [];

  // 2. 料仓温度传感器配置
  final List<ThresholdConfig> tempConfigs = [];

  // 3. 震动传感器 (RMS) 配置
  final List<ThresholdConfig> vibRmsConfigs = [];

  // 4. 震动传感器 (温度) 配置
  final List<ThresholdConfig> vibTempConfigs = [];

  // 5. 电表 (功率) 配置
  final List<ThresholdConfig> elecPowerConfigs = [];

  // 6. 电表 (电流) 配置
  final List<ThresholdConfig> elecCurrentConfigs = [];

  // ============================================================
  // 初始化构造
  // ============================================================
  RealtimeConfigProvider() {
    _initDefaultConfigs();
  }

  /// 初始化默认配置结构
  void _initDefaultConfigs() {
    for (int i = 1; i <= _hopperCount; i++) {
      // PM10 (默认: 正常<150, 警告<250 ug/m3)
      pm10Configs.add(ThresholdConfig(
        key: 'hopper_${i}_pm10',
        displayName: '#$i 料仓 PM10',
        normalMax: 150.0,
        warningMax: 250.0,
      ));

      // 温度 (默认: 正常<50, 警告<70 °C)
      tempConfigs.add(ThresholdConfig(
        key: 'hopper_${i}_temp',
        displayName: '#$i 料仓温度',
        normalMax: 50.0,
        warningMax: 70.0,
      ));

      // 震动 RMS (默认: 正常<4, 警告<7 mm/s - 参考ISO)
      vibRmsConfigs.add(ThresholdConfig(
        key: 'hopper_${i}_vib_rms',
        displayName: '#$i 震动(RMS)',
        normalMax: 4.5,
        warningMax: 7.1,
      ));

      // 震动 温度 (默认: 正常<60, 警告<80 °C)
      vibTempConfigs.add(ThresholdConfig(
        key: 'hopper_${i}_vib_temp',
        displayName: '#$i 震动传感器温度',
        normalMax: 60.0,
        warningMax: 80.0,
      ));

      // 电表 功率 (默认: 正常<10, 警告<15 kW - 假设值)
      elecPowerConfigs.add(ThresholdConfig(
        key: 'hopper_${i}_power',
        displayName: '#$i 电机功率',
        normalMax: 10.0,
        warningMax: 15.0,
      ));

      // 电表 电流 (默认: 正常<20, 警告<30 A - 假设值)
      elecCurrentConfigs.add(ThresholdConfig(
        key: 'hopper_${i}_current',
        displayName: '#$i 电机电流',
        normalMax: 20.0,
        warningMax: 30.0,
      ));
    }
    _buildCache();
  }

  /// 构建缓存
  void _buildCache() {
    _cache.clear();
    for (var c in pm10Configs) _cache[c.key] = c;
    for (var c in tempConfigs) _cache[c.key] = c;
    for (var c in vibRmsConfigs) _cache[c.key] = c;
    for (var c in vibTempConfigs) _cache[c.key] = c;
    for (var c in elecPowerConfigs) _cache[c.key] = c;
    for (var c in elecCurrentConfigs) _cache[c.key] = c;
  }

  /// 加载配置
  Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);

      if (jsonStr != null) {
        final Map<String, dynamic> jsonMap = json.decode(jsonStr);
        _loadFromJson(jsonMap, pm10Configs);
        _loadFromJson(jsonMap, tempConfigs);
        _loadFromJson(jsonMap, vibRmsConfigs);
        _loadFromJson(jsonMap, vibTempConfigs);
        _loadFromJson(jsonMap, elecPowerConfigs);
        _loadFromJson(jsonMap, elecCurrentConfigs);
        _buildCache();
      }
    } catch (e) {
      debugPrint('Error loading realtime config: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  void _loadFromJson(
      Map<String, dynamic> jsonMap, List<ThresholdConfig> targetList) {
    for (int i = 0; i < targetList.length; i++) {
      final current = targetList[i];
      if (jsonMap.containsKey(current.key)) {
        final saved = ThresholdConfig.fromJson(jsonMap[current.key]);
        targetList[i] = current.copyWith(
          normalMax: saved.normalMax,
          warningMax: saved.warningMax,
        );
      }
    }
  }

  /// 保存配置
  Future<bool> saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> jsonMap = {};

      _addToJson(jsonMap, pm10Configs);
      _addToJson(jsonMap, tempConfigs);
      _addToJson(jsonMap, vibRmsConfigs);
      _addToJson(jsonMap, vibTempConfigs);
      _addToJson(jsonMap, elecPowerConfigs);
      _addToJson(jsonMap, elecCurrentConfigs);

      return await prefs.setString(_storageKey, json.encode(jsonMap));
    } catch (e) {
      debugPrint('Error saving realtime config: $e');
      return false;
    }
  }

  void _addToJson(Map<String, dynamic> jsonMap, List<ThresholdConfig> list) {
    for (var config in list) {
      jsonMap[config.key] = config.toJson();
    }
  }

  // ============================================================
  // 更新方法
  // ============================================================

  void updateConfig(String key, {double? normalMax, double? warningMax}) {
    // 查找并更新
    _updateInList(pm10Configs, key, normalMax, warningMax);
    _updateInList(tempConfigs, key, normalMax, warningMax);
    _updateInList(vibRmsConfigs, key, normalMax, warningMax);
    _updateInList(vibTempConfigs, key, normalMax, warningMax);
    _updateInList(elecPowerConfigs, key, normalMax, warningMax);
    _updateInList(elecCurrentConfigs, key, normalMax, warningMax);

    _buildCache();
    notifyListeners();
  }

  void _updateInList(List<ThresholdConfig> list, String key, double? normalMax,
      double? warningMax) {
    final index = list.indexWhere((c) => c.key == key);
    if (index != -1) {
      list[index] = list[index].copyWith(
        normalMax: normalMax,
        warningMax: warningMax,
      );
    }
  }

  /// 重置为默认
  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    pm10Configs.clear();
    tempConfigs.clear();
    vibRmsConfigs.clear();
    vibTempConfigs.clear();
    elecPowerConfigs.clear();
    elecCurrentConfigs.clear();

    _initDefaultConfigs();
    notifyListeners();
  }

  // ============================================================
  // 颜色获取 API (O(1) 复杂度)
  // ============================================================

  Color getThresholdColor(String key, double value) {
    final config = _cache[key];
    // 如果找不到配置，返回默认正常颜色
    if (config == null) return ThresholdColors.normal;
    return config.getColor(value);
  }

  ThresholdConfig? getConfig(String key) => _cache[key];
}
