// WebSocket 实时数据响应模型
class HopperRealtimeResponse {
  final String type;
  final bool success;
  final String timestamp;
  final String source;
  final Map<String, HopperData> data;

  HopperRealtimeResponse({
    required this.type,
    required this.success,
    required this.timestamp,
    required this.source,
    required this.data,
  });

  factory HopperRealtimeResponse.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>? ?? {};
    final Map<String, HopperData> hopperDataMap = {};

    // 1. 提取振动传感器设备的 vibration 模块 (来自 DB6)
    Map<String, dynamic>? vibrationModuleRaw;
    String? vibrationDeviceKey;
    dataMap.forEach((key, value) {
      if (value is Map<String, dynamic> &&
          value['device_type'] == 'vibration_sensor') {
        final modules = value['modules'] as Map<String, dynamic>? ?? {};
        if (modules.containsKey('vibration')) {
          vibrationModuleRaw = modules['vibration'] as Map<String, dynamic>?;
        }
        vibrationDeviceKey = key;
      }
    });

    // 2. 解析所有设备，跳过振动传感器，将振动模块合并到主设备
    dataMap.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        if (key == vibrationDeviceKey) return; // 跳过振动传感器设备

        // 将振动模块注入主设备的 modules
        if (vibrationModuleRaw != null) {
          final modules = value['modules'] as Map<String, dynamic>? ?? {};
          modules['vibration'] = vibrationModuleRaw;
          value['modules'] = modules;
        }

        hopperDataMap[key] = HopperData.fromJson(value);
      }
    });

    return HopperRealtimeResponse(
      type: json['type'] ?? 'realtime_data',
      success: json['success'] ?? true,
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      source: json['source'] ?? 'plc',
      data: hopperDataMap,
    );
  }
}

class HopperDevice {
  final String deviceId;
  final String deviceType;
  final String? dbNumber;

  HopperDevice({
    required this.deviceId,
    required this.deviceType,
    this.dbNumber,
  });

  factory HopperDevice.fromJson(Map<String, dynamic> json) {
    return HopperDevice(
      deviceId: json['device_id'] ?? '',
      deviceType: json['device_type'] ?? '',
      dbNumber: json['db_number']?.toString(),
    );
  }
}

class HopperData {
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String? timestamp;
  final WeighSensor? weighSensor;
  final Pm10Module? pm10Module;
  final TemperatureModule? temperatureModule;
  final TemperatureModule? temperatureModule1; // 长料仓第1个温度
  final TemperatureModule? temperatureModule2; // 长料仓第2个温度
  final ElectricityModule? electricityModule;
  final VibrationModule? vibrationModule;

  HopperData({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    this.timestamp,
    this.weighSensor,
    this.pm10Module,
    this.temperatureModule,
    this.temperatureModule1,
    this.temperatureModule2,
    this.electricityModule,
    this.vibrationModule,
  });

  factory HopperData.fromJson(Map<String, dynamic> json) {
    final modules = json['modules'] as Map<String, dynamic>? ?? {};

    return HopperData(
      deviceId: json['device_id'] ?? '',
      deviceName: json['device_name'] ?? json['device_id'] ?? '',
      deviceType: json['device_type'] ?? 'hopper_sensor_unit',
      timestamp: json['timestamp'],
      weighSensor: modules.containsKey('weight')
          ? WeighSensor.fromJson(modules['weight']['fields'] ?? {})
          : (modules.containsKey('WeighSensor')
              ? WeighSensor.fromJson(modules['WeighSensor'])
              : null),
      pm10Module: modules.containsKey('pm10')
          ? Pm10Module.fromJson(modules['pm10']['fields'] ?? {})
          : (modules.containsKey('PM10Sensor')
              ? Pm10Module.fromJson(modules['PM10Sensor'])
              : null),
      temperatureModule: modules.containsKey('temperature')
          ? TemperatureModule.fromJson(modules['temperature']['fields'] ?? {})
          : (modules.containsKey('temp')
              ? TemperatureModule.fromJson(modules['temp']['fields'] ?? {})
              : (modules.containsKey('TemperatureSensor')
                  ? TemperatureModule.fromJson(modules['TemperatureSensor'])
                  : null)),
      // 长料仓温度1
      temperatureModule1: modules.containsKey('temp1')
          ? TemperatureModule.fromJson(modules['temp1']['fields'] ?? {})
          : null,
      // 长料仓温度2
      temperatureModule2: modules.containsKey('temp2')
          ? TemperatureModule.fromJson(modules['temp2']['fields'] ?? {})
          : null,
      // 三相电表（支持多种标签）
      electricityModule: modules.containsKey('electricity')
          ? ElectricityModule.fromJson(modules['electricity']['fields'] ?? {})
          : (modules.containsKey('meter')
              ? ElectricityModule.fromJson(modules['meter']['fields'] ?? {})
              : (modules.containsKey('elec')
                  ? ElectricityModule.fromJson(modules['elec']['fields'] ?? {})
                  : (modules.containsKey('ElectricityMeter')
                      ? ElectricityModule.fromJson(modules['ElectricityMeter'])
                      : null))),
      vibrationModule: _parseVibration(modules),
    );
  }

  static VibrationModule? _parseVibration(Map<String, dynamic> modules) {
    Map<String, dynamic>? raw;
    if (modules.containsKey('vibration')) {
      raw = modules['vibration']['fields'] ?? {};
    } else if (modules.containsKey('vibration_selected')) {
      raw = modules['vibration_selected']['fields'] ?? {};
    } else if (modules.containsKey('VibrationSelected')) {
      raw = modules['VibrationSelected'];
    }

    if (raw == null) return null;
    return VibrationModule.fromJson(raw);
  }

  /// 用于本地缓存的序列化 (简化格式)
  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_name': deviceName,
        'device_type': deviceType,
        'timestamp': timestamp,
        'modules': {
          if (weighSensor != null) 'WeighSensor': weighSensor!.toJson(),
          if (pm10Module != null) 'PM10Sensor': pm10Module!.toJson(),
          if (temperatureModule != null)
            'TemperatureSensor': temperatureModule!.toJson(),
          if (temperatureModule1 != null)
            'temp1': {'fields': temperatureModule1!.toJson()},
          if (temperatureModule2 != null)
            'temp2': {'fields': temperatureModule2!.toJson()},
          if (electricityModule != null)
            'ElectricityMeter': electricityModule!.toJson(),
          if (vibrationModule != null)
            'vibration': {'fields': vibrationModule!.toJson()},
        },
      };
}

// PM10 粉尘浓度模块（后端：module_type=pm10）
class Pm10Module {
  final double pm10Value;

  Pm10Module({required this.pm10Value});

  factory Pm10Module.fromJson(Map<String, dynamic> json) {
    return Pm10Module(
      pm10Value: (json['pm10_value'] as num?)?.toDouble() ??
          (json['pm10'] as num?)?.toDouble() ??
          (json['concentration'] as num?)?.toDouble() ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() => {'pm10_value': pm10Value};
}

// 温度传感器模块（后端：module_type=temperature）
class TemperatureModule {
  final double temperatureValue;

  TemperatureModule({required this.temperatureValue});

  factory TemperatureModule.fromJson(Map<String, dynamic> json) {
    return TemperatureModule(
      temperatureValue: (json['temperature_value'] as num?)?.toDouble() ??
          (json['temperature'] as num?)?.toDouble() ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() => {'temperature_value': temperatureValue};
}

// 三相电表模块（后端：module_type=electricity）
class ElectricityModule {
  final double pt; // 总有功功率 (kW)
  final double impEp; // 正向有功总电能 (kWh)
  final double voltage; // A相电压 Ua_0 (V)
  final double voltageB; // B相电压 Ua_1 (V)
  final double voltageC; // C相电压 Ua_2 (V)
  final double currentA; // A相电流 (A)
  final double currentB; // B相电流 (A)
  final double currentC; // C相电流 (A)

  ElectricityModule({
    required this.pt,
    required this.impEp,
    required this.voltage,
    required this.voltageB,
    required this.voltageC,
    required this.currentA,
    required this.currentB,
    required this.currentC,
  });

  factory ElectricityModule.fromJson(Map<String, dynamic> json) {
    return ElectricityModule(
      pt: (json['Pt'] as num?)?.toDouble() ?? 0.0,
      impEp: (json['ImpEp'] as num?)?.toDouble() ?? 0.0,
      voltage: (json['Ua_0'] as num?)?.toDouble() ?? 0.0,
      voltageB: (json['Ua_1'] as num?)?.toDouble() ?? 0.0,
      voltageC: (json['Ua_2'] as num?)?.toDouble() ?? 0.0,
      currentA: (json['I_0'] as num?)?.toDouble() ?? 0.0,
      currentB: (json['I_1'] as num?)?.toDouble() ?? 0.0,
      currentC: (json['I_2'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'Pt': pt,
        'ImpEp': impEp,
        'Ua_0': voltage,
        'Ua_1': voltageB,
        'Ua_2': voltageC,
        'I_0': currentA,
        'I_1': currentB,
        'I_2': currentC,
      };
}

// 振动传感器模块（后端：module_type=vibration）
// 后端输出 9 个字段: vx/vy/vz (速度mm/s), dx/dy/dz (位移um), hzx/hzy/hzz (频率Hz)
class VibrationModule {
  // 速度幅值 (mm/s)
  final double vx;
  final double vy;
  final double vz;
  // 位移幅值 (um)
  final double dx;
  final double dy;
  final double dz;
  // 频率 (Hz)
  final double freqX;
  final double freqY;
  final double freqZ;

  VibrationModule({
    required this.vx,
    required this.vy,
    required this.vz,
    required this.dx,
    required this.dy,
    required this.dz,
    required this.freqX,
    required this.freqY,
    required this.freqZ,
  });

  factory VibrationModule.fromJson(Map<String, dynamic> json) {
    double readNum(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) return value.toDouble();
      }
      return 0.0;
    }

    return VibrationModule(
      vx: readNum(['vx', 'VX']),
      vy: readNum(['vy', 'VY']),
      vz: readNum(['vz', 'VZ']),
      dx: readNum(['dx', 'DX']),
      dy: readNum(['dy', 'DY']),
      dz: readNum(['dz', 'DZ']),
      freqX: readNum(['hzx', 'HZX', 'freq_x', 'FreqX']),
      freqY: readNum(['hzy', 'HZY', 'freq_y', 'FreqY']),
      freqZ: readNum(['hzz', 'HZZ', 'freq_z', 'FreqZ']),
    );
  }

  Map<String, dynamic> toJson() => {
        'vx': vx,
        'vy': vy,
        'vz': vz,
        'dx': dx,
        'dy': dy,
        'dz': dz,
        'hzx': freqX,
        'hzy': freqY,
        'hzz': freqZ,
      };
}

// 保留旧的类名作为别名（兼容性）
typedef Pm10Sensor = Pm10Module;
typedef TemperatureSensor = TemperatureModule;
typedef ElectricityMeter = ElectricityModule;
typedef VibrationData = VibrationModule;

class WeighSensor {
  final double weight;
  final double feedRate;

  WeighSensor({required this.weight, required this.feedRate});

  factory WeighSensor.fromJson(Map<String, dynamic> json) {
    return WeighSensor(
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      feedRate: (json['feed_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'feed_rate': feedRate,
      };
}
