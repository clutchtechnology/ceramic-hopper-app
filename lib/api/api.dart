// 后端API地址统一管理

class Api {
  static const String baseUrl = 'http://localhost:8080';

  // 健康检查
  static const String health = '/api/health';
  static const String healthPlc = '/api/health/plc';
  static const String healthDb = '/api/health/database';
  static const String healthLatestTimestamp = '/api/health/latest-timestamp';

  // 料仓
  static const String hopperRealtimeBatch = '/api/hopper/realtime/batch';
  static String hopperRealtime(String deviceId) => '/api/hopper/$deviceId';
  static String hopperHistory(String deviceId) =>
      '/api/hopper/$deviceId/history';

  // 辊道窑
  static const String rollerInfo = '/api/roller/info';
  static const String rollerRealtime = '/api/roller/realtime';
  static const String rollerRealtimeFormatted =
      '/api/roller/realtime/formatted';
  static const String rollerHistory = '/api/roller/history';
  static String rollerZone(String zoneId) => '/api/roller/zone/$zoneId';

  // SCR
  static const String scrRealtimeBatch = '/api/scr/realtime/batch';
  static String scrRealtime(String deviceId) => '/api/scr/$deviceId';
  static String scrHistory(String deviceId) => '/api/scr/$deviceId/history';

  // 风机
  static const String fanRealtimeBatch = '/api/fan/realtime/batch';
  static String fanRealtime(String deviceId) => '/api/fan/$deviceId';
  static String fanHistory(String deviceId) => '/api/fan/$deviceId/history';

  // SCR+风机统一接口
  static const String scrFanRealtimeBatch = '/api/scr-fan/realtime/batch';

  // 配置
  static const String configServer = '/api/config/server';
  static const String configPlc = '/api/config/plc';
  static const String configPlcTest = '/api/config/plc/test';

  // 传感器状态位 (后端解析)
  static const String statusAll = '/api/status'; // 按DB分组
  static const String statusFlat = '/api/status/flat'; // 扁平列表
  static String statusDb(int dbNumber) => '/api/status/db/$dbNumber'; // 单个DB
}
