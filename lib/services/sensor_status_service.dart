// ============================================================
// 文件说明: sensor_status_service.dart - 设备状态位API服务
// ============================================================
// 功能:
//   - 获取 DB3/DB7/DB11 状态位数据
//   - 后端已解析，前端直接使用
// ============================================================

import '../api/index.dart';
import '../api/api.dart';
import '../models/sensor_status_model.dart';

/// 🔧 [CRITICAL] 使用 ApiClient 单例，避免创建多个 HTTP Client 导致连接泄漏
class SensorStatusService {
  final ApiClient _client = ApiClient();

  /// 获取所有状态位数据 (按 DB 分组)
  Future<AllStatusResponse> getAllStatus() async {
    try {
      final response = await _client.get(Api.statusAll);

      if (response is Map<String, dynamic>) {
        return AllStatusResponse.fromJson(response);
      } else {
        return AllStatusResponse(
          success: false,
          error: '响应格式错误',
        );
      }
    } catch (e) {
      return AllStatusResponse(
        success: false,
        error: '网络错误: $e',
      );
    }
  }

  /// 获取单个 DB 块的状态数据
  Future<List<ModuleStatus>?> getDbStatus(int dbNumber) async {
    try {
      final response = await _client.get(Api.statusDb(dbNumber));

      if (response is Map<String, dynamic> &&
          response['success'] == true &&
          response['data'] != null) {
        return (response['data'] as List)
            .map((item) => ModuleStatus.fromJson(item))
            .toList();
      }
      return null;
    } catch (e) {
      // 使用 ApiClient 内置的错误日志，无需重复打印
      return null;
    }
  }
}
