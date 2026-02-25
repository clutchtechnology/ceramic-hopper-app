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
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30; // 最大重连间隔 30 秒

  // 心跳控制
  static const Duration _heartbeatInterval = Duration(seconds: 15);

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
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];

      switch (type) {
        case 'realtime_data':
          _handleRealtimeData(data);
          break;
        case 'heartbeat':
          // 服务端心跳回复，无需处理
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

  // 6. 处理实时数据
  void _handleRealtimeData(Map<String, dynamic> data) {
    try {
      final response = HopperRealtimeResponse.fromJson(data);

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

  // 12. 更新连接状态
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
