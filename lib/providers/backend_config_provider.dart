import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import '../api/index.dart';

/// 后端配置 Provider
/// 用于持久化存储服务器配置和PLC配置
///
/// 存储键值:
/// - 服务器配置: backend_server_config
/// - PLC配置: backend_plc_config

/// 服务器配置数据模型
class ServerConfigData {
  final String host;
  final int port;
  final bool debug;

  ServerConfigData({
    required this.host,
    required this.port,
    required this.debug,
  });

  factory ServerConfigData.fromJson(Map<String, dynamic> json) {
    return ServerConfigData(
      host: json['host'] as String? ?? '0.0.0.0',
      port: json['port'] as int? ?? 8080,
      debug: json['debug'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'debug': debug,
      };

  ServerConfigData copyWith({
    String? host,
    int? port,
    bool? debug,
  }) {
    return ServerConfigData(
      host: host ?? this.host,
      port: port ?? this.port,
      debug: debug ?? this.debug,
    );
  }
}

/// PLC配置数据模型
class PlcConfigData {
  String ipAddress;
  int rack;
  int slot;
  int timeoutMs;
  int pollInterval;

  PlcConfigData({
    required this.ipAddress,
    required this.rack,
    required this.slot,
    required this.timeoutMs,
    required this.pollInterval,
  });

  factory PlcConfigData.fromJson(Map<String, dynamic> json) {
    return PlcConfigData(
      ipAddress: json['ip_address'] as String? ?? '192.168.50.223',
      rack: json['rack'] as int? ?? 0,
      slot: json['slot'] as int? ?? 1,
      timeoutMs: json['timeout_ms'] as int? ?? 5000,
      pollInterval: json['poll_interval'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() => {
        'ip_address': ipAddress,
        'rack': rack,
        'slot': slot,
        'timeout_ms': timeoutMs,
        'poll_interval': pollInterval,
      };

  /// 用于PUT请求的JSON（只包含可修改字段）
  Map<String, dynamic> toUpdateJson() => {
        'ip_address': ipAddress,
        'poll_interval': pollInterval,
      };

  PlcConfigData copyWith({
    String? ipAddress,
    int? rack,
    int? slot,
    int? timeoutMs,
    int? pollInterval,
  }) {
    return PlcConfigData(
      ipAddress: ipAddress ?? this.ipAddress,
      rack: rack ?? this.rack,
      slot: slot ?? this.slot,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      pollInterval: pollInterval ?? this.pollInterval,
    );
  }
}

/// 后端配置 Provider
/// 负责与后端API交互并持久化配置
///
/// 业务流程:
/// 1. 初始化时先从本地 SharedPreferences 加载缓存配置
/// 2. 然后从后端 API 刷新最新配置
/// 3. 更新配置时: 先推送到后端 -> 成功后保存本地
class BackendConfigProvider extends ChangeNotifier {
  // 1, SharedPreferences 存储键 - 服务器配置
  static const String _serverConfigKey = 'backend_server_config';
  // 2, SharedPreferences 存储键 - PLC配置
  static const String _plcConfigKey = 'backend_plc_config';

  // 3, 配置加载完成标志 (用于UI显示加载状态)
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // 4, 服务器配置数据 (host/port/debug)
  ServerConfigData? _serverConfig;
  // 5, PLC配置数据 (ip_address/rack/slot/timeout_ms/poll_interval)
  PlcConfigData? _plcConfig;
  // 6, API请求进行中标志
  bool _isLoading = false;
  // 7, 最近一次操作的错误信息
  String? _error;

  ServerConfigData? get serverConfig => _serverConfig;
  PlcConfigData? get plcConfig => _plcConfig;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 初始化：先从本地加载，再从后端刷新
  /// 调用时机: App启动时在 main.dart 或 Provider 初始化时调用
  Future<void> initialize() async {
    // 1, 先从本地 SharedPreferences 加载缓存配置 (离线可用)
    await _loadFromLocal();
    // 然后从后端 API 刷新最新配置
    await refreshFromBackend();
    // 3, 标记配置加载完成
    _isLoaded = true;
    notifyListeners();
  }

  /// 仅从本地加载配置（不连接后端）
  Future<void> loadConfig() async {
    await _loadFromLocal();
    _isLoaded = true;
    notifyListeners();
  }

  /// 从本地存储加载配置
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1, 加载服务器配置 (使用存储键 _serverConfigKey)
      final serverJson = prefs.getString(_serverConfigKey);
      if (serverJson != null) {
        // 4, 解析并赋值服务器配置
        _serverConfig = ServerConfigData.fromJson(jsonDecode(serverJson));
      }

      // 2, 加载PLC配置 (使用存储键 _plcConfigKey)
      final plcJson = prefs.getString(_plcConfigKey);
      if (plcJson != null) {
        // 5, 解析并赋值PLC配置
        _plcConfig = PlcConfigData.fromJson(jsonDecode(plcJson));
      }

      notifyListeners();
    } catch (e) {
      // 7, 记录错误但不中断流程 (本地缓存失败不影响后端刷新)
      debugPrint('从本地加载配置失败: $e');
    }
  }

  /// 保存配置到本地存储
  Future<bool> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_serverConfig != null) {
        await prefs.setString(
            _serverConfigKey, jsonEncode(_serverConfig!.toJson()));
      }

      if (_plcConfig != null) {
        await prefs.setString(_plcConfigKey, jsonEncode(_plcConfig!.toJson()));
      }
      return true;
    } catch (e) {
      debugPrint('保存配置到本地失败: $e');
      return false;
    }
  }

  /// 从后端刷新配置
  /// 调用时机: 初始化时 / 用户手动刷新 / 设置页面进入时
  Future<void> refreshFromBackend() async {
    // 6, 设置加载状态
    _isLoading = true;
    // 7, 清除旧错误
    _error = null;
    notifyListeners();

    final client = ApiClient();

    try {
      // 获取服务器配置 (GET /api/config/server)
      final serverData = await client.get(Api.configServer);
      if (serverData['success'] == true && serverData['data'] != null) {
        // 4, 更新服务器配置
        _serverConfig = ServerConfigData.fromJson(serverData['data']);
      }

      // 获取PLC配置 (GET /api/config/plc)
      final plcData = await client.get(Api.configPlc);
      if (plcData['success'] == true && plcData['data'] != null) {
        // 5, 更新PLC配置
        _plcConfig = PlcConfigData.fromJson(plcData['data']);
      }

      // 1,2, 保存到本地缓存 (使用 _serverConfigKey 和 _plcConfigKey)
      await _saveToLocal();

      // 6, 清除加载状态
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // 7, 记录错误信息
      _error = '无法连接到后端服务: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 更新PLC配置
  Future<bool> updatePlcConfig(PlcConfigData newConfig) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final client = ApiClient();

    try {
      final data = await client.put(
        Api.configPlc,
        body: newConfig.toUpdateJson(),
      );

      if (data['success'] == true) {
        // 更新本地配置
        _plcConfig = newConfig;
        await _saveToLocal();

        // 从后端刷新确认
        await refreshFromBackend();
        return true;
      } else {
        _error = data['error'] ?? '更新失败';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '网络错误: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 测试PLC连接
  Future<Map<String, dynamic>> testPlcConnection() async {
    final client = ApiClient();

    try {
      final data = await client.post(Api.configPlcTest);

      return {
        'success': data['success'] == true,
        'message': data['data']?['message'] ?? data['error'] ?? '未知结果',
        'connected': data['data']?['connected'] ?? false,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '网络错误: $e',
        'connected': false,
      };
    }
  }

  /// 保存配置（手动触发保存）
  Future<bool> saveConfig() async {
    return await _saveToLocal();
  }

  /// 重置为默认配置
  void resetToDefault() {
    _serverConfig = ServerConfigData(
      host: '0.0.0.0',
      port: 8080,
      debug: false,
    );
    _plcConfig = PlcConfigData(
      ipAddress: '192.168.50.223',
      rack: 0,
      slot: 1,
      timeoutMs: 5000,
      pollInterval: 5,
    );
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
