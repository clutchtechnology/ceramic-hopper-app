/// 料仓阈值配置状态管理 Provider
///
/// 功能职责:
/// - 本地持久化存储阈值配置 (SharedPreferences)
/// - 提供阈值颜色判断接口 (正常/警告/报警)
/// - 支持实时更新和重置默认值
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 阈值颜色配置 (固定三色)
class ThresholdColors {
  static const Color normal = Color(0xFF00ff88); // 绿色 - 正常
  static const Color warning = Color(0xFFffcc00); // 黄色 - 警告
  static const Color alarm = Color(0xFFff3b30); // 红色 - 报警
}

/// 单个参数的阈值配置
class ThresholdConfig {
  final String key; // 配置键值
  final String displayName; // 显示名称
  double normalMax; // 正常上限 (绿色)
  double warningMax; // 警告上限 (黄色，超过为红色)

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

  /// 根据数值获取状态颜色
  /// value <= normalMax: 绿色 (正常)
  /// normalMax < value <= warningMax: 黄色 (警告)
  /// value > warningMax: 红色 (报警)
  Color getColor(double value) {
    if (value <= normalMax) {
      return ThresholdColors.normal;
    } else if (value <= warningMax) {
      return ThresholdColors.warning;
    } else {
      return ThresholdColors.alarm;
    }
  }

  /// 获取状态文本
  String getStatus(double value) {
    if (value <= normalMax) {
      return '正常';
    } else if (value <= warningMax) {
      return '警告';
    } else {
      return '报警';
    }
  }
}

/// 料仓阈值配置 Provider
/// 用于持久化存储料仓监控系统的报警阈值
///
/// 包含：
/// - PM10 粉尘浓度阈值
/// - 温度阈值
/// - 三相电压阈值 (A/B/C)
/// - 三相电流阈值 (A/B/C)
/// - 功率阈值
/// - XYZ 速度阈值
/// - XYZ 频率阈值
class HopperThresholdProvider extends ChangeNotifier {
  static const String _storageKey = 'hopper_threshold_config_v1';

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // ============================================================
  // PM10 粉尘浓度阈值
  // ============================================================
  ThresholdConfig pm10Config = ThresholdConfig(
    key: 'pm10',
    displayName: 'PM10 粉尘浓度',
    normalMax: 75.0,
    warningMax: 150.0,
  );

  // ============================================================
  // 温度阈值
  // ============================================================
  ThresholdConfig temperatureConfig = ThresholdConfig(
    key: 'temperature',
    displayName: '温度',
    normalMax: 60.0,
    warningMax: 80.0,
  );

  // ============================================================
  // 三相电压阈值 (A/B/C)
  // ============================================================
  ThresholdConfig voltageAConfig = ThresholdConfig(
    key: 'voltage_a',
    displayName: 'A相电压',
    normalMax: 400.0,
    warningMax: 420.0,
  );

  ThresholdConfig voltageBConfig = ThresholdConfig(
    key: 'voltage_b',
    displayName: 'B相电压',
    normalMax: 400.0,
    warningMax: 420.0,
  );

  ThresholdConfig voltageCConfig = ThresholdConfig(
    key: 'voltage_c',
    displayName: 'C相电压',
    normalMax: 400.0,
    warningMax: 420.0,
  );

  // ============================================================
  // 三相电流阈值 (A/B/C)
  // ============================================================
  ThresholdConfig currentAConfig = ThresholdConfig(
    key: 'current_a',
    displayName: 'A相电流',
    normalMax: 50.0,
    warningMax: 80.0,
  );

  ThresholdConfig currentBConfig = ThresholdConfig(
    key: 'current_b',
    displayName: 'B相电流',
    normalMax: 50.0,
    warningMax: 80.0,
  );

  ThresholdConfig currentCConfig = ThresholdConfig(
    key: 'current_c',
    displayName: 'C相电流',
    normalMax: 50.0,
    warningMax: 80.0,
  );

  // ============================================================
  // 功率阈值
  // ============================================================
  ThresholdConfig powerConfig = ThresholdConfig(
    key: 'power',
    displayName: '功率',
    normalMax: 10.0,
    warningMax: 15.0,
  );

  // ============================================================
  // XYZ 速度阈值
  // ============================================================
  ThresholdConfig speedXConfig = ThresholdConfig(
    key: 'speed_x',
    displayName: 'X轴速度',
    normalMax: 5.0,
    warningMax: 10.0,
  );

  ThresholdConfig speedYConfig = ThresholdConfig(
    key: 'speed_y',
    displayName: 'Y轴速度',
    normalMax: 5.0,
    warningMax: 10.0,
  );

  ThresholdConfig speedZConfig = ThresholdConfig(
    key: 'speed_z',
    displayName: 'Z轴速度',
    normalMax: 5.0,
    warningMax: 10.0,
  );

  // ============================================================
  // XYZ 频率阈值
  // ============================================================
  ThresholdConfig freqXConfig = ThresholdConfig(
    key: 'freq_x',
    displayName: 'X轴频率',
    normalMax: 50.0,
    warningMax: 60.0,
  );

  ThresholdConfig freqYConfig = ThresholdConfig(
    key: 'freq_y',
    displayName: 'Y轴频率',
    normalMax: 50.0,
    warningMax: 60.0,
  );

  ThresholdConfig freqZConfig = ThresholdConfig(
    key: 'freq_z',
    displayName: 'Z轴频率',
    normalMax: 50.0,
    warningMax: 60.0,
  );

  /// 从本地存储加载配置
  Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        _loadFromJson(jsonData);
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('加载阈值配置失败: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  void _loadFromJson(Map<String, dynamic> json) {
    // 加载 PM10 配置
    if (json['pm10'] != null) {
      final data = json['pm10'] as Map<String, dynamic>;
      pm10Config.normalMax = (data['normalMax'] as num?)?.toDouble() ?? pm10Config.normalMax;
      pm10Config.warningMax = (data['warningMax'] as num?)?.toDouble() ?? pm10Config.warningMax;
    }

    // 加载温度配置
    if (json['temperature'] != null) {
      final data = json['temperature'] as Map<String, dynamic>;
      temperatureConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? temperatureConfig.normalMax;
      temperatureConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? temperatureConfig.warningMax;
    }

    // 加载三相电压配置
    if (json['voltage_a'] != null) {
      final data = json['voltage_a'] as Map<String, dynamic>;
      voltageAConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? voltageAConfig.normalMax;
      voltageAConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? voltageAConfig.warningMax;
    }
    if (json['voltage_b'] != null) {
      final data = json['voltage_b'] as Map<String, dynamic>;
      voltageBConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? voltageBConfig.normalMax;
      voltageBConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? voltageBConfig.warningMax;
    }
    if (json['voltage_c'] != null) {
      final data = json['voltage_c'] as Map<String, dynamic>;
      voltageCConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? voltageCConfig.normalMax;
      voltageCConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? voltageCConfig.warningMax;
    }

    // 加载三相电流配置
    if (json['current_a'] != null) {
      final data = json['current_a'] as Map<String, dynamic>;
      currentAConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? currentAConfig.normalMax;
      currentAConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? currentAConfig.warningMax;
    }
    if (json['current_b'] != null) {
      final data = json['current_b'] as Map<String, dynamic>;
      currentBConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? currentBConfig.normalMax;
      currentBConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? currentBConfig.warningMax;
    }
    if (json['current_c'] != null) {
      final data = json['current_c'] as Map<String, dynamic>;
      currentCConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? currentCConfig.normalMax;
      currentCConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? currentCConfig.warningMax;
    }

    // 加载功率配置
    if (json['power'] != null) {
      final data = json['power'] as Map<String, dynamic>;
      powerConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? powerConfig.normalMax;
      powerConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? powerConfig.warningMax;
    }

    // 加载 XYZ 速度配置
    if (json['speed_x'] != null) {
      final data = json['speed_x'] as Map<String, dynamic>;
      speedXConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? speedXConfig.normalMax;
      speedXConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? speedXConfig.warningMax;
    }
    if (json['speed_y'] != null) {
      final data = json['speed_y'] as Map<String, dynamic>;
      speedYConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? speedYConfig.normalMax;
      speedYConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? speedYConfig.warningMax;
    }
    if (json['speed_z'] != null) {
      final data = json['speed_z'] as Map<String, dynamic>;
      speedZConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? speedZConfig.normalMax;
      speedZConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? speedZConfig.warningMax;
    }

    // 加载 XYZ 频率配置
    if (json['freq_x'] != null) {
      final data = json['freq_x'] as Map<String, dynamic>;
      freqXConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? freqXConfig.normalMax;
      freqXConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? freqXConfig.warningMax;
    }
    if (json['freq_y'] != null) {
      final data = json['freq_y'] as Map<String, dynamic>;
      freqYConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? freqYConfig.normalMax;
      freqYConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? freqYConfig.warningMax;
    }
    if (json['freq_z'] != null) {
      final data = json['freq_z'] as Map<String, dynamic>;
      freqZConfig.normalMax = (data['normalMax'] as num?)?.toDouble() ?? freqZConfig.normalMax;
      freqZConfig.warningMax = (data['warningMax'] as num?)?.toDouble() ?? freqZConfig.warningMax;
    }
  }

  Map<String, dynamic> _toJson() {
    return {
      'pm10': {
        'normalMax': pm10Config.normalMax,
        'warningMax': pm10Config.warningMax,
      },
      'temperature': {
        'normalMax': temperatureConfig.normalMax,
        'warningMax': temperatureConfig.warningMax,
      },
      'voltage_a': {
        'normalMax': voltageAConfig.normalMax,
        'warningMax': voltageAConfig.warningMax,
      },
      'voltage_b': {
        'normalMax': voltageBConfig.normalMax,
        'warningMax': voltageBConfig.warningMax,
      },
      'voltage_c': {
        'normalMax': voltageCConfig.normalMax,
        'warningMax': voltageCConfig.warningMax,
      },
      'current_a': {
        'normalMax': currentAConfig.normalMax,
        'warningMax': currentAConfig.warningMax,
      },
      'current_b': {
        'normalMax': currentBConfig.normalMax,
        'warningMax': currentBConfig.warningMax,
      },
      'current_c': {
        'normalMax': currentCConfig.normalMax,
        'warningMax': currentCConfig.warningMax,
      },
      'power': {
        'normalMax': powerConfig.normalMax,
        'warningMax': powerConfig.warningMax,
      },
      'speed_x': {
        'normalMax': speedXConfig.normalMax,
        'warningMax': speedXConfig.warningMax,
      },
      'speed_y': {
        'normalMax': speedYConfig.normalMax,
        'warningMax': speedYConfig.warningMax,
      },
      'speed_z': {
        'normalMax': speedZConfig.normalMax,
        'warningMax': speedZConfig.warningMax,
      },
      'freq_x': {
        'normalMax': freqXConfig.normalMax,
        'warningMax': freqXConfig.warningMax,
      },
      'freq_y': {
        'normalMax': freqYConfig.normalMax,
        'warningMax': freqYConfig.warningMax,
      },
      'freq_z': {
        'normalMax': freqZConfig.normalMax,
        'warningMax': freqZConfig.warningMax,
      },
    };
  }

  /// 保存配置到本地存储
  Future<bool> saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_toJson());
      await prefs.setString(_storageKey, jsonString);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('保存阈值配置失败: $e');
      return false;
    }
  }

  /// 重置为默认配置
  void resetToDefault() {
    pm10Config.normalMax = 75.0;
    pm10Config.warningMax = 150.0;

    temperatureConfig.normalMax = 60.0;
    temperatureConfig.warningMax = 80.0;

    voltageAConfig.normalMax = 400.0;
    voltageAConfig.warningMax = 420.0;
    voltageBConfig.normalMax = 400.0;
    voltageBConfig.warningMax = 420.0;
    voltageCConfig.normalMax = 400.0;
    voltageCConfig.warningMax = 420.0;

    currentAConfig.normalMax = 50.0;
    currentAConfig.warningMax = 80.0;
    currentBConfig.normalMax = 50.0;
    currentBConfig.warningMax = 80.0;
    currentCConfig.normalMax = 50.0;
    currentCConfig.warningMax = 80.0;

    powerConfig.normalMax = 10.0;
    powerConfig.warningMax = 15.0;

    speedXConfig.normalMax = 5.0;
    speedXConfig.warningMax = 10.0;
    speedYConfig.normalMax = 5.0;
    speedYConfig.warningMax = 10.0;
    speedZConfig.normalMax = 5.0;
    speedZConfig.warningMax = 10.0;

    freqXConfig.normalMax = 50.0;
    freqXConfig.warningMax = 60.0;
    freqYConfig.normalMax = 50.0;
    freqYConfig.warningMax = 60.0;
    freqZConfig.normalMax = 50.0;
    freqZConfig.warningMax = 60.0;

    notifyListeners();
  }

  // ============================================================
  // 便捷获取颜色的方法
  // ============================================================

  /// 获取 PM10 颜色
  Color getPM10Color(double value) => pm10Config.getColor(value);

  /// 获取温度颜色
  Color getTemperatureColor(double value) => temperatureConfig.getColor(value);

  /// 获取 A 相电压颜色
  Color getVoltageAColor(double value) => voltageAConfig.getColor(value);

  /// 获取 B 相电压颜色
  Color getVoltageBColor(double value) => voltageBConfig.getColor(value);

  /// 获取 C 相电压颜色
  Color getVoltageCColor(double value) => voltageCConfig.getColor(value);

  /// 获取 A 相电流颜色
  Color getCurrentAColor(double value) => currentAConfig.getColor(value);

  /// 获取 B 相电流颜色
  Color getCurrentBColor(double value) => currentBConfig.getColor(value);

  /// 获取 C 相电流颜色
  Color getCurrentCColor(double value) => currentCConfig.getColor(value);

  /// 获取功率颜色
  Color getPowerColor(double value) => powerConfig.getColor(value);

  /// 获取 X 轴速度颜色
  Color getSpeedXColor(double value) => speedXConfig.getColor(value);

  /// 获取 Y 轴速度颜色
  Color getSpeedYColor(double value) => speedYConfig.getColor(value);

  /// 获取 Z 轴速度颜色
  Color getSpeedZColor(double value) => speedZConfig.getColor(value);

  /// 获取 X 轴频率颜色
  Color getFreqXColor(double value) => freqXConfig.getColor(value);

  /// 获取 Y 轴频率颜色
  Color getFreqYColor(double value) => freqYConfig.getColor(value);

  /// 获取 Z 轴频率颜色
  Color getFreqZColor(double value) => freqZConfig.getColor(value);
}

