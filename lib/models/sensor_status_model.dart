// ============================================================
// 文件说明: sensor_status_model.dart - 设备状态位数据模型
// ============================================================
// 功能:
//   - 定义设备状态位数据结构
//   - 解析后端返回的结构化 JSON 数据
// ============================================================

/// 单个模块的状态数据 (后端已解析)
class ModuleStatus {
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String moduleTag;
  final String description;
  final int dbNumber;
  final int offset;
  final bool error;
  final int statusCode;
  final String statusHex;
  final bool isNormal;
  final String? timestamp;

  ModuleStatus({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.moduleTag,
    required this.description,
    required this.dbNumber,
    required this.offset,
    required this.error,
    required this.statusCode,
    required this.statusHex,
    required this.isNormal,
    this.timestamp,
  });

  factory ModuleStatus.fromJson(Map<String, dynamic> json) {
    return ModuleStatus(
      deviceId: json['device_id'] ?? '',
      deviceName: json['device_name'] ?? '',
      deviceType: json['device_type'] ?? '',
      moduleTag: json['module_tag'] ?? '',
      description: json['description'] ?? '',
      dbNumber: json['db_number'] ?? 0,
      offset: json['offset'] ?? 0,
      error: json['error'] ?? false,
      statusCode: json['status_code'] ?? 0,
      statusHex: json['status_hex'] ?? '0000',
      isNormal: json['is_normal'] ?? true,
      timestamp: json['timestamp'],
    );
  }
}

/// 统计信息
class StatusSummary {
  final int total;
  final int normal;
  final int error;

  StatusSummary({
    required this.total,
    required this.normal,
    required this.error,
  });

  factory StatusSummary.fromJson(Map<String, dynamic> json) {
    return StatusSummary(
      total: json['total'] ?? 0,
      normal: json['normal'] ?? 0,
      error: json['error'] ?? 0,
    );
  }
}

/// 所有状态位的响应数据 (按 DB 分组)
class AllStatusResponse {
  final bool success;
  final Map<String, List<ModuleStatus>>? data; // "db3", "db7", "db11"
  final StatusSummary? summary;
  final String? error;

  AllStatusResponse({
    required this.success,
    this.data,
    this.summary,
    this.error,
  });

  factory AllStatusResponse.fromJson(Map<String, dynamic> json) {
    Map<String, List<ModuleStatus>>? dataMap;

    if (json['data'] != null && json['data'] is Map) {
      dataMap = {};
      (json['data'] as Map).forEach((key, value) {
        if (value is List) {
          dataMap![key] = value
              .map(
                  (item) => ModuleStatus.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      });
    }

    return AllStatusResponse(
      success: json['success'] ?? false,
      data: dataMap,
      summary: json['summary'] != null
          ? StatusSummary.fromJson(json['summary'])
          : null,
      error: json['error'],
    );
  }

  /// 获取所有状态的扁平列表
  List<ModuleStatus> get flatList {
    if (data == null) return [];
    final List<ModuleStatus> result = [];
    for (final key in ['db3', 'db7', 'db11']) {
      if (data!.containsKey(key)) {
        result.addAll(data![key]!);
      }
    }
    return result;
  }
}
