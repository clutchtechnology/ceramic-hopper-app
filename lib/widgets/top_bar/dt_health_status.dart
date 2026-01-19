import 'dart:async';
import 'package:flutter/material.dart';
import '../../api/index.dart';
import '../../api/api.dart';
import '../../utils/app_logger.dart';
import '../data_display/data_tech_line_widgets.dart';

class HealthStatusWidget extends StatefulWidget {
  const HealthStatusWidget({super.key});

  @override
  State<HealthStatusWidget> createState() => _HealthStatusWidgetState();
}

class _HealthStatusWidgetState extends State<HealthStatusWidget> {
  // ===== 状态变量 =====
  // 1-3, 当前健康状态 → build() 中显示指示器
  bool _isSystemHealthy = false;
  bool _isPlcHealthy = false;
  bool _isDbHealthy = false;

  // 4, 定时器 → dispose() 中取消
  Timer? _timer;

  // 5-7, 上次状态 → 检测状态变化，避免重复日志
  bool? _lastSystemHealthy;
  bool? _lastPlcHealthy;
  bool? _lastDbHealthy;

  // 🔧 网络异常退避
  int _consecutiveFailures = 0;
  static const int _normalIntervalMinutes = 1;
  static const int _maxIntervalMinutes = 5;

  // ===== 生命周期 =====
  @override
  void initState() {
    super.initState();
    _checkHealth();
    // 4, 启动定时健康检查（每分钟一次）
    _startPolling(_normalIntervalMinutes);
  }

  /// 🔧 启动轮询（支持动态间隔）
  void _startPolling(int intervalMinutes) {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(minutes: intervalMinutes), (_) {
      if (mounted) _checkHealth();
    });
  }

  // 4, 取消定时器防止内存泄漏
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ===== 健康检查逻辑 =====
  /// 更新健康状态并记录状态变化日志
  void _updateHealthStatus({
    required String serviceName,
    required bool newValue,
    required bool? lastValue,
    required void Function(bool) updateLast,
    required void Function(bool) updateCurrent,
    Object? errorDetail,
  }) {
    if (!mounted) return;

    // 状态变化时记录日志
    if (newValue && lastValue == false) {
      logger.info('$serviceName恢复正常');
    } else if (!newValue && lastValue != false) {
      if (errorDetail != null) {
        logger.error('$serviceName不可用', errorDetail);
      } else {
        logger.error('$serviceName连接断开');
      }
    }

    updateLast(newValue);
    setState(() => updateCurrent(newValue));
  }

  Future<void> _checkHealth() async {
    final client = ApiClient();

    bool allHealthy = true;

    // 1, 检查系统服务健康状态
    if (!await _checkSystemHealth(client)) allHealthy = false;
    // 2, 检查 PLC 连接状态
    if (!await _checkPlcHealth(client)) allHealthy = false;
    // 3, 检查数据库连接状态
    if (!await _checkDbHealth(client)) allHealthy = false;

    // 🔧 根据健康状态调整轮询间隔
    _adjustPollingInterval(allHealthy);
  }

  /// 🔧 调整轮询间隔
  void _adjustPollingInterval(bool allHealthy) {
    if (!mounted) return;

    if (allHealthy) {
      if (_consecutiveFailures > 0) {
        _consecutiveFailures = 0;
        _startPolling(_normalIntervalMinutes);
      }
    } else {
      final previousFailures = _consecutiveFailures;
      _consecutiveFailures = (_consecutiveFailures + 1).clamp(0, 3);
      if (_consecutiveFailures != previousFailures) {
        final newInterval =
            (_normalIntervalMinutes * (1 << _consecutiveFailures))
                .clamp(_normalIntervalMinutes, _maxIntervalMinutes);
        _startPolling(newInterval);
      }
    }
  }

  // 1, 系统服务健康检查
  Future<bool> _checkSystemHealth(ApiClient client) async {
    try {
      await client.get(Api.health);
      _updateHealthStatus(
        serviceName: '系统服务',
        newValue: true,
        lastValue: _lastSystemHealthy,
        updateLast: (v) => _lastSystemHealthy = v,
        updateCurrent: (v) => _isSystemHealthy = v,
      );
      return true;
    } catch (e) {
      _updateHealthStatus(
        serviceName: '系统服务',
        newValue: false,
        lastValue: _lastSystemHealthy,
        updateLast: (v) => _lastSystemHealthy = v,
        updateCurrent: (v) => _isSystemHealthy = v,
        errorDetail: e,
      );
      return false;
    }
  }

  // 2, PLC 连接状态检查
  Future<bool> _checkPlcHealth(ApiClient client) async {
    try {
      final response = await client.get(Api.healthPlc);
      final plcConnected = _parseConnected(response);
      _updateHealthStatus(
        serviceName: 'PLC',
        newValue: plcConnected,
        lastValue: _lastPlcHealthy,
        updateLast: (v) => _lastPlcHealthy = v,
        updateCurrent: (v) => _isPlcHealthy = v,
      );
      return plcConnected;
    } catch (e) {
      _updateHealthStatus(
        serviceName: 'PLC',
        newValue: false,
        lastValue: _lastPlcHealthy,
        updateLast: (v) => _lastPlcHealthy = v,
        updateCurrent: (v) => _isPlcHealthy = v,
        errorDetail: e,
      );
      return false;
    }
  }

  // 3, 数据库连接状态检查
  Future<bool> _checkDbHealth(ApiClient client) async {
    try {
      final response = await client.get(Api.healthDb);
      final dbConnected = _parseDbStatus(response);
      _updateHealthStatus(
        serviceName: '数据库',
        newValue: dbConnected,
        lastValue: _lastDbHealthy,
        updateLast: (v) => _lastDbHealthy = v,
        updateCurrent: (v) => _isDbHealthy = v,
      );
      return dbConnected;
    } catch (e) {
      _updateHealthStatus(
        serviceName: '数据库',
        newValue: false,
        lastValue: _lastDbHealthy,
        updateLast: (v) => _lastDbHealthy = v,
        updateCurrent: (v) => _isDbHealthy = v,
        errorDetail: e,
      );
      return false;
    }
  }

  /// 解析 {"data": {"connected": true}} 格式的响应
  bool _parseConnected(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data['connected'] == true;
      }
    }
    return false;
  }

  /// 解析数据库状态响应（支持两种格式）
  /// - {"data": {"status": "healthy"}}
  /// - {"data": {"databases": {"influxdb": {"connected": true}}}}
  bool _parseDbStatus(dynamic response) {
    if (response is! Map<String, dynamic>) return false;
    final data = response['data'];
    if (data is! Map<String, dynamic>) return false;

    // 格式1: status == "healthy"
    if (data['status'] == 'healthy') return true;

    // 格式2: databases.influxdb.connected
    final databases = data['databases'];
    if (databases is Map<String, dynamic>) {
      final influxdb = databases['influxdb'];
      if (influxdb is Map<String, dynamic>) {
        return influxdb['connected'] == true;
      }
    }
    return false;
  }

  // ===== UI 构建 =====
  @override
  Widget build(BuildContext context) {
    // 1-3, 显示三个服务的健康状态指示器
    return Row(
      children: [
        _buildStatusIndicator('服务', _isSystemHealthy), // 1
        const SizedBox(width: 8),
        _buildStatusIndicator('PLC', _isPlcHealthy), // 2
        const SizedBox(width: 8),
        _buildStatusIndicator('数据库', _isDbHealthy), // 3
      ],
    );
  }

  Widget _buildStatusIndicator(String label, bool isHealthy) {
    final color = isHealthy ? TechColors.glowGreen : TechColors.glowRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TechColors.bgMedium,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ],
      ),
    );
  }
}
