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
  final String? timestamp;
  final WeighSensor? weighSensor;
  final Pm10Sensor? pm10Sensor;
  final TemperatureSensor? temperatureSensor;
  final TemperatureSensor? temperatureSensor1; // 长料仓第1个温度
  final TemperatureSensor? temperatureSensor2; // 长料仓第2个温度
  final ElectricityMeter? electricityMeter;
  final VibrationData? vibration;

  HopperData({
    required this.deviceId,
    this.timestamp,
    this.weighSensor,
    this.pm10Sensor,
    this.temperatureSensor,
    this.temperatureSensor1,
    this.temperatureSensor2,
    this.electricityMeter,
    this.vibration,
  });

  factory HopperData.fromJson(Map<String, dynamic> json) {
    final modules = json['modules'] as Map<String, dynamic>? ?? {};

    return HopperData(
      deviceId: json['device_id'] ?? '',
      timestamp: json['timestamp'],
      weighSensor: modules.containsKey('weight')
          ? WeighSensor.fromJson(modules['weight']['fields'] ?? {})
          : (modules.containsKey('WeighSensor')
              ? WeighSensor.fromJson(modules['WeighSensor'])
              : null),
      pm10Sensor: modules.containsKey('pm10')
          ? Pm10Sensor.fromJson(modules['pm10']['fields'] ?? {})
          : (modules.containsKey('PM10Sensor')
              ? Pm10Sensor.fromJson(modules['PM10Sensor'])
              : null),
      temperatureSensor: modules.containsKey('temp')
          ? TemperatureSensor.fromJson(modules['temp']['fields'] ?? {})
          : (modules.containsKey('TemperatureSensor')
              ? TemperatureSensor.fromJson(modules['TemperatureSensor'])
              : null),
      // ✅ 长料仓温度1
      temperatureSensor1: modules.containsKey('temp1')
          ? TemperatureSensor.fromJson(modules['temp1']['fields'] ?? {})
          : null,
      // ✅ 长料仓温度2
      temperatureSensor2: modules.containsKey('temp2')
          ? TemperatureSensor.fromJson(modules['temp2']['fields'] ?? {})
          : null,
      // ✅ 修正：使用 'meter' 标签（与后端配置一致）
      electricityMeter: modules.containsKey('meter')
          ? ElectricityMeter.fromJson(modules['meter']['fields'] ?? {})
          : (modules.containsKey('elec')
              ? ElectricityMeter.fromJson(modules['elec']['fields'] ?? {})
              : (modules.containsKey('ElectricityMeter')
                  ? ElectricityMeter.fromJson(modules['ElectricityMeter'])
                  : null)),
      vibration: _parseVibration(modules),
    );
  }

  static VibrationData? _parseVibration(Map<String, dynamic> modules) {
    Map<String, dynamic>? raw;
    if (modules.containsKey('vibration')) {
      raw = modules['vibration']['fields'] ?? {};
    } else if (modules.containsKey('vibration_selected')) {
      raw = modules['vibration_selected']['fields'] ?? {};
    } else if (modules.containsKey('VibrationSelected')) {
      raw = modules['VibrationSelected'];
    }

    if (raw == null) return null;
    return VibrationData.fromJson(raw);
  }

  /// 用于本地缓存的序列化 (简化格式)
  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'timestamp': timestamp,
        'modules': {
          if (weighSensor != null) 'WeighSensor': weighSensor!.toJson(),
          if (pm10Sensor != null) 'PM10Sensor': pm10Sensor!.toJson(),
          if (temperatureSensor != null)
            'TemperatureSensor': temperatureSensor!.toJson(),
          if (temperatureSensor1 != null)
            'temp1': {'fields': temperatureSensor1!.toJson()},
          if (temperatureSensor2 != null)
            'temp2': {'fields': temperatureSensor2!.toJson()},
          if (electricityMeter != null)
            'ElectricityMeter': electricityMeter!.toJson(),
          if (vibration != null) 'vibration': {'fields': vibration!.toJson()},
        },
      };
}

class VibrationData {
  final double dx;
  final double dy;
  final double dz;
  final double freqX;
  final double freqY;
  final double freqZ;
  final double kx;
  final double ky;
  final double kz;
  final double vrmsX;
  final double vrmsY;
  final double vrmsZ;

  VibrationData({
    required this.dx,
    required this.dy,
    required this.dz,
    required this.freqX,
    required this.freqY,
    required this.freqZ,
    required this.kx,
    required this.ky,
    required this.kz,
    required this.vrmsX,
    required this.vrmsY,
    required this.vrmsZ,
  });

  factory VibrationData.fromJson(Map<String, dynamic> json) {
    double readNum(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) return value.toDouble();
      }
      return 0.0;
    }

    return VibrationData(
      dx: readNum(['dx', 'DX', 'dxValue']),
      dy: readNum(['dy', 'DY', 'dyValue']),
      dz: readNum(['dz', 'DZ', 'dzValue']),
      freqX: readNum(['freq_x', 'HZX', 'hzx', 'FreqX']),
      freqY: readNum(['freq_y', 'HZY', 'hzy', 'FreqY']),
      freqZ: readNum(['freq_z', 'HZZ', 'hzz', 'FreqZ']),
      kx: readNum(['k_x', 'kx', 'KX', 'acc_peak_x']),
      ky: readNum(['k_y', 'ky', 'KY', 'acc_peak_y']),
      kz: readNum(['k_z', 'kz', 'KZ', 'acc_peak_z']),
      vrmsX: readNum(['vrms_x', 'VRMSX', 'vrmsX']),
      vrmsY: readNum(['vrms_y', 'VRMSY', 'vrmsY']),
      vrmsZ: readNum(['vrms_z', 'VRMSZ', 'VRMGZ', 'vrmsZ']),
    );
  }

  Map<String, dynamic> toJson() => {
        'dx': dx,
        'dy': dy,
        'dz': dz,
        'freq_x': freqX,
        'freq_y': freqY,
        'freq_z': freqZ,
        'kx': kx,
        'ky': ky,
        'kz': kz,
        'vrms_x': vrmsX,
        'vrms_y': vrmsY,
        'vrms_z': vrmsZ,
      };
}

class Pm10Sensor {
  final double pm10;
  final double pm25;
  final double pm1;

  Pm10Sensor({
    required this.pm10,
    required this.pm25,
    required this.pm1,
  });

  factory Pm10Sensor.fromJson(Map<String, dynamic> json) {
    return Pm10Sensor(
      pm10: (json['pm10'] as num?)?.toDouble() ??
          (json['concentration'] as num?)?.toDouble() ??
          0.0,
      pm25: (json['pm2_5'] as num?)?.toDouble() ?? 0.0,
      pm1: (json['pm1_0'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'pm10': pm10,
        'pm2_5': pm25,
        'pm1_0': pm1,
      };
}

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

class TemperatureSensor {
  final double temperature;

  TemperatureSensor({required this.temperature});

  factory TemperatureSensor.fromJson(Map<String, dynamic> json) {
    return TemperatureSensor(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
      };
}

/// 电表数据模型 (精简版 - 7个关键字段)
/// 后端存储: Pt, ImpEp, Ua_0, I_0, I_1, I_2 (都除以10, 电流已乘变比)
class ElectricityMeter {
  final double pt; // 总有功功率 (kW)
  final double impEp; // 正向有功总电能 (kWh)
  final double voltage; // A相电压 (V) - 只保留A相
  final double currentA; // A相电流 (A)
  final double currentB; // B相电流 (A)
  final double currentC; // C相电流 (A)

  ElectricityMeter({
    required this.pt,
    required this.impEp,
    required this.voltage,
    required this.currentA,
    required this.currentB,
    required this.currentC,
  });

  factory ElectricityMeter.fromJson(Map<String, dynamic> json) {
    return ElectricityMeter(
      pt: (json['Pt'] as num?)?.toDouble() ?? 0.0,
      impEp: (json['ImpEp'] as num?)?.toDouble() ?? 0.0,
      voltage: (json['Ua_0'] as num?)?.toDouble() ?? 0.0,
      currentA: (json['I_0'] as num?)?.toDouble() ?? 0.0,
      currentB: (json['I_1'] as num?)?.toDouble() ?? 0.0,
      currentC: (json['I_2'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'Pt': pt,
        'ImpEp': impEp,
        'Ua_0': voltage,
        'I_0': currentA,
        'I_1': currentB,
        'I_2': currentC,
      };
}
