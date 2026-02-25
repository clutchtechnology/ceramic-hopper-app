import '../api/index.dart';
import '../api/api.dart';
import '../models/hopper_model.dart';
import 'websocket_service.dart';
import 'package:flutter/foundation.dart';

class HopperService {
  final ApiClient _client = ApiClient();
  final WebSocketService _wsService = WebSocketService();

  // WebSocket 实时数据回调
  Function(HopperRealtimeResponse)? onRealtimeDataUpdate;

  // 1. 订阅 WebSocket 实时数据
  void subscribeRealtime() {
    // 设置回调
    _wsService.onRealtimeDataUpdate = (response) {
      if (onRealtimeDataUpdate != null) {
        onRealtimeDataUpdate!(response);
      }
    };

    // 连接并订阅
    _wsService.connect().then((_) {
      _wsService.subscribeRealtime();
    });
  }

  // 2. 取消订阅
  void unsubscribe() {
    _wsService.onRealtimeDataUpdate = null;
  }

  // 3. 获取 WebSocket 连接状态
  WebSocketState get connectionState => _wsService.state;

  // 4. 批量获取所有料仓实时数据（HTTP 降级）
  Future<Map<String, HopperData>> getHopperBatchData(
      {String? hopperType}) async {
    try {
      final response = await _client.get(
        Api.hopperRealtimeBatch,
        params: hopperType != null ? {'hopper_type': hopperType} : null,
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data != null && data['devices'] is List) {
          final Map<String, HopperData> result = {};
          for (var deviceData in data['devices']) {
            final hopperData = HopperData.fromJson(deviceData);
            result[hopperData.deviceId] = hopperData;
          }
          return result;
        }
      }
      return {};
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching hopper batch data: $e');
      return {};
    }
  }

  // 5. 获取单个料仓实时数据（HTTP 降级）
  Future<HopperData?> getHopperData(String deviceId) async {
    try {
      final response = await _client.get(Api.hopperRealtime(deviceId));
      if (response['success'] == true && response['data'] != null) {
        return HopperData.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      if (kDebugMode)
        debugPrint('Error fetching hopper data for $deviceId: $e');
      return null;
    }
  }
}
