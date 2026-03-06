// WebSocket 连接服务 - 料仓监控系统
// 功能: 单例 WebSocket 连接管理，支持自动重连、心跳检测、消息分发

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/hopper_model.dart';
import '../utils/app_logger.dart';

enum WebSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class WebSocketService {
  // 单例模式
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // WebSocket 连接
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // 连接状态
  WebSocketState _state = WebSocketState.disconnected;
  WebSocketState get state => _state;

  // 重连控制
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _dataFreshnessTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30; // 最大重连间隔 30 秒

  // 心跳控制
  static const Duration _heartbeatInterval = Duration(seconds: 15);

  // [CRITICAL] 消息级节流: 后端 0.1s 推送，但 fromJson 反序列化 + 模型创建开销大
  // 每秒 10 次反序列化会产生巨量临时对象，长时间运行后 GC 压力导致主线程卡死
  // 节流到 1s，将反序列化频率从 10次/秒 降到 1次/秒
  DateTime _lastRealtimeProcess = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _messageProcessThrottle = Duration(seconds: 1);

  // [FIX] 数据新鲜度检测 - 防止后端阻塞导致连接存活但数据停止推送
  DateTime? _lastDataReceivedTime;
  static const Duration _dataFreshnessTimeout = Duration(seconds: 60);
  static const Duration _dataFreshnessCheckInterval = Duration(seconds: 10);

  // WebSocket URL (使用 Api 统一配置)
  final String wsUrl = 'ws://localhost:8082/ws/realtime';

  // 回调函数
  Function(HopperRealtimeResponse)? onRealtimeDataUpdate;
  Function(WebSocketState)? onStateChanged;
  Function(String)? onError;

  // 1. 连接到 WebSocket 服务器
  Future<void> connect() async {
    if (_state == WebSocketState.connected ||
        _state == WebSocketState.connecting) {
      logger.info('[WS] 已连接或正在连接中');
      return;
    }

    _updateState(WebSocketState.connecting);

    try {
      logger.info('[WS] 正在连接到 $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // 监听消息
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onConnectionError,
        onDone: _onConnectionClosed,
        cancelOnError: false,
      );

      _updateState(WebSocketState.connected);
      _reconnectAttempts = 0;

      logger.info('[WS] 连接成功');

      // 启动心跳
      _startHeartbeat();

      // [FIX] 启动数据新鲜度检测
      _startDataFreshnessCheck();

      // 自动订阅实时数据频道 (重连后需要重新订阅)
      subscribeRealtime();
    } catch (e) {
      logger.error('[WS] 连接失败: $e');
      _updateState(WebSocketState.disconnected);
      _scheduleReconnect();
    }
  }

  // 2. 断开连接
  void disconnect() {
    logger.info('[WS] 主动断开连接');

    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _dataFreshnessTimer?.cancel();

    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);

    _channel = null;
    _subscription = null;

    _updateState(WebSocketState.disconnected);
  }

  // 3. 订阅实时数据频道
  void subscribeRealtime() {
    if (_state != WebSocketState.connected) {
      logger.warning('[WS] 未连接，无法订阅');
      return;
    }

    final message = {
      'type': 'subscribe',
      'channel': 'realtime',
    };

    send(message);
    logger.info('[WS] 已订阅 realtime 频道');
  }

  // 4. 发送消息
  void send(Map<String, dynamic> message) {
    if (_state != WebSocketState.connected || _channel == null) {
      logger.warning('[WS] 未连接，无法发送消息');
      return;
    }

    try {
      final jsonString = jsonEncode(message);
      _channel!.sink.add(jsonString);
    } catch (e) {
      logger.error('[WS] 发送消息失败: $e');
    }
  }

  // 5. 处理接收到的消息
  // [CRITICAL] 使用 String.contains 预检查，在 jsonDecode 之前完成节流
  // 避免 10Hz 全量 jsonDecode 导致长时间运行后 GC 压力累积卡死主线程
  void _onMessage(dynamic message) {
    try {
      final msgStr = message as String;

      // 5.1 realtime_data 快速路径: 先用字符串匹配判断类型，再节流，最后才 jsonDecode
      if (msgStr.contains('"realtime_data"')) {
        _lastDataReceivedTime = DateTime.now();
        final now = DateTime.now();
        if (now.difference(_lastRealtimeProcess) < _messageProcessThrottle) {
          return; // 节流期内直接丢弃，不执行 jsonDecode
        }
        _lastRealtimeProcess = now;
        final data = jsonDecode(msgStr);
        _handleRealtimeData(data);
        return;
      }

      // 5.2 非 realtime_data 消息 (heartbeat/error 等): 频率极低，正常解析
      final data = jsonDecode(msgStr);
      final type = data['type'];

      switch (type) {
        case 'heartbeat':
          break;
        case 'error':
          _handleError(data);
          break;
        default:
          logger.debug('[WS] 未知消息类型: $type');
      }
    } catch (e) {
      logger.error('[WS] 解析消息失败: $e');
    }
  }

  // 6. 处理实时数据 (仅在节流通过时调用，减少 fromJson 开销)
  void _handleRealtimeData(Map<String, dynamic> data) {
    try {
      final response = HopperRealtimeResponse.fromJson(data);

      // 注意: _lastDataReceivedTime 已在 _onMessage 中更新，此处不再重复

      if (onRealtimeDataUpdate != null) {
        onRealtimeDataUpdate!(response);
      }

      logger.debug('[WS] 收到实时数据: ${response.data.keys.length} 个设备');
    } catch (e) {
      logger.error('[WS] 处理实时数据失败: $e');
    }
  }

  // 7. 处理错误消息
  void _handleError(Map<String, dynamic> data) {
    final errorMsg = data['message'] ?? '未知错误';
    logger.error('[WS] 服务端错误: $errorMsg');

    if (onError != null) {
      onError!(errorMsg);
    }
  }

  // 8. 连接错误处理
  void _onConnectionError(error) {
    logger.error('[WS] 连接错误: $error');
    _updateState(WebSocketState.disconnected);
    _scheduleReconnect();
  }

  // 9. 连接关闭处理
  void _onConnectionClosed() {
    logger.warning('[WS] 连接已关闭');

    if (_state != WebSocketState.disconnected) {
      _updateState(WebSocketState.disconnected);
      _scheduleReconnect();
    }
  }

  // 10. 调度重连
  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return;
    }

    _reconnectAttempts++;

    // 指数退避: 1s, 2s, 4s, 8s, 16s, 30s (最大)
    final delay = (_reconnectAttempts <= 5)
        ? (1 << (_reconnectAttempts - 1))
        : _maxReconnectDelay;

    logger.info('[WS] 将在 $delay 秒后重连 (第 $_reconnectAttempts 次尝试)');

    _updateState(WebSocketState.reconnecting);

    _reconnectTimer = Timer(Duration(seconds: delay), () {
      connect();
    });
  }

  // 11. 启动心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_state == WebSocketState.connected) {
        final heartbeat = {
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
        };
        send(heartbeat);
        logger.debug('[WS] 发送心跳');
      }
    });
  }

  // 12. [FIX] 数据新鲜度检测 - 如果连接正常但长时间没有收到数据，强制重连
  void _startDataFreshnessCheck() {
    _dataFreshnessTimer?.cancel();
    _lastDataReceivedTime = DateTime.now();

    _dataFreshnessTimer = Timer.periodic(_dataFreshnessCheckInterval, (timer) {
      if (_state != WebSocketState.connected) {
        return;
      }

      if (_lastDataReceivedTime == null) {
        return;
      }

      final elapsed = DateTime.now().difference(_lastDataReceivedTime!);
      if (elapsed > _dataFreshnessTimeout) {
        logger.warning(
          '[WS] 数据新鲜度超时: 已 ${elapsed.inSeconds} 秒未收到实时数据，强制重连',
        );

        // 强制断开并重连
        _heartbeatTimer?.cancel();
        _dataFreshnessTimer?.cancel();
        _subscription?.cancel();
        try {
          _channel?.sink.close(status.goingAway);
        } catch (_) {}
        _channel = null;
        _subscription = null;

        _updateState(WebSocketState.disconnected);
        _scheduleReconnect();
      }
    });
  }

  // 13. 更新连接状态
  void _updateState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;

      if (onStateChanged != null) {
        onStateChanged!(newState);
      }

      logger.info('[WS] 状态变化: $newState');
    }
  }

  // 13. 释放资源
  void dispose() {
    disconnect();
    onRealtimeDataUpdate = null;
    onStateChanged = null;
    onError = null;
  }
}
