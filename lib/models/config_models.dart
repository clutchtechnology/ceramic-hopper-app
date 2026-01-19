/// 配置数据模型
/// 用于系统配置页的各类设备和服务器配置

/// 服务器配置
class ServerConfig {
  String ipAddress;
  int port;

  ServerConfig({
    this.ipAddress = '192.168.1.100',
    this.port = 8080,
  });

  Map<String, dynamic> toJson() => {
        'ipAddress': ipAddress,
        'port': port,
      };

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      ipAddress: json['ipAddress'] as String? ?? '192.168.1.100',
      port: json['port'] as int? ?? 8080,
    );
  }
}

/// PLC 配置
class PLCConfig {
  String ipAddress;
  int port;
  int rack;
  int slot;
  String protocol; // 'S7-1200', 'S7-1500', etc.

  PLCConfig({
    this.ipAddress = '192.168.0.1',
    this.port = 102,
    this.rack = 0,
    this.slot = 1,
    this.protocol = 'S7-1200',
  });

  Map<String, dynamic> toJson() => {
        'ipAddress': ipAddress,
        'port': port,
        'rack': rack,
        'slot': slot,
        'protocol': protocol,
      };

  factory PLCConfig.fromJson(Map<String, dynamic> json) {
    return PLCConfig(
      ipAddress: json['ipAddress'] as String? ?? '192.168.0.1',
      port: json['port'] as int? ?? 102,
      rack: json['rack'] as int? ?? 0,
      slot: json['slot'] as int? ?? 1,
      protocol: json['protocol'] as String? ?? 'S7-1200',
    );
  }
}

/// 数据库配置
class DatabaseConfig {
  String host;
  int port;
  String username;
  String password;
  String databaseName;

  DatabaseConfig({
    this.host = 'localhost',
    this.port = 3306,
    this.username = 'root',
    this.password = '',
    this.databaseName = 'ceramic_workshop',
  });

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'databaseName': databaseName,
      };

  factory DatabaseConfig.fromJson(Map<String, dynamic> json) {
    return DatabaseConfig(
      host: json['host'] as String? ?? 'localhost',
      port: json['port'] as int? ?? 3306,
      username: json['username'] as String? ?? 'root',
      password: json['password'] as String? ?? '',
      databaseName: json['databaseName'] as String? ?? 'ceramic_workshop',
    );
  }
}

/// 传感器配置
class SensorConfig {
  String id;
  String name;
  String type; // 'temperature', 'pressure', 'flow', etc.
  int modbusAddress;
  int dataPoint;
  String unit;
  bool enabled;

  SensorConfig({
    required this.id,
    required this.name,
    this.type = 'temperature',
    this.modbusAddress = 0,
    this.dataPoint = 0,
    this.unit = '℃',
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'modbusAddress': modbusAddress,
        'dataPoint': dataPoint,
        'unit': unit,
        'enabled': enabled,
      };

  factory SensorConfig.fromJson(Map<String, dynamic> json) {
    return SensorConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'temperature',
      modbusAddress: json['modbusAddress'] as int? ?? 0,
      dataPoint: json['dataPoint'] as int? ?? 0,
      unit: json['unit'] as String? ?? '℃',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

/// 系统配置（包含所有配置）
class SystemConfig {
  ServerConfig serverConfig;
  PLCConfig plcConfig;
  DatabaseConfig databaseConfig;
  List<SensorConfig> sensors;

  SystemConfig({
    ServerConfig? serverConfig,
    PLCConfig? plcConfig,
    DatabaseConfig? databaseConfig,
    List<SensorConfig>? sensors,
  })  : serverConfig = serverConfig ?? ServerConfig(),
        plcConfig = plcConfig ?? PLCConfig(),
        databaseConfig = databaseConfig ?? DatabaseConfig(),
        sensors = sensors ?? [];

  Map<String, dynamic> toJson() => {
        'serverConfig': serverConfig.toJson(),
        'plcConfig': plcConfig.toJson(),
        'databaseConfig': databaseConfig.toJson(),
        'sensors': sensors.map((s) => s.toJson()).toList(),
      };

  factory SystemConfig.fromJson(Map<String, dynamic> json) {
    return SystemConfig(
      serverConfig: ServerConfig.fromJson(
          json['serverConfig'] as Map<String, dynamic>? ?? {}),
      plcConfig:
          PLCConfig.fromJson(json['plcConfig'] as Map<String, dynamic>? ?? {}),
      databaseConfig: DatabaseConfig.fromJson(
          json['databaseConfig'] as Map<String, dynamic>? ?? {}),
      sensors: (json['sensors'] as List<dynamic>?)
              ?.map((s) => SensorConfig.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
