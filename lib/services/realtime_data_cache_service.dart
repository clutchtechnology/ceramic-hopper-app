import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/hopper_model.dart';
import '../utils/app_logger.dart';

/// 实时数据缓存服务
/// 用于持久化存储最后一次成功获取的实时数据，App 重启后可恢复显示
///
/// 🔧 性能优化:
/// - 节流机制: 最小30秒写入间隔，避免频繁I/O
/// - 防并发: 使用标志位防止并发写入冲突
class RealtimeDataCacheService {
  static final RealtimeDataCacheService _instance =
      RealtimeDataCacheService._internal();
  factory RealtimeDataCacheService() => _instance;
  RealtimeDataCacheService._internal();

  static const String _cacheFileName = 'realtime_data_cache.json';
  File? _cacheFile;

  // 🔧 节流控制: 最小写入间隔30秒
  DateTime? _lastSaveTime;
  static const Duration _minSaveInterval = Duration(seconds: 30);
  bool _isSaving = false; // 防止并发写入

  /// 初始化缓存文件路径
  Future<void> _ensureCacheFile() async {
    if (_cacheFile != null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final dataDir = Directory('${directory.path}/ceramic_workshop');
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }
      _cacheFile = File('${dataDir.path}/$_cacheFileName');
      logger.info('缓存文件路径: ${_cacheFile!.path}');
    } catch (e, stack) {
      logger.error('初始化缓存文件失败', e, stack);
    }
  }

  /// 保存缓存数据
  /// 🔧 节流优化: 最小30秒间隔，防止频繁I/O导致卡顿
  Future<void> saveCache({
    required Map<String, HopperData> hopperData,
  }) async {
    // 🔧 节流检查: 距上次保存不足30秒则跳过
    final now = DateTime.now();
    if (_lastSaveTime != null &&
        now.difference(_lastSaveTime!) < _minSaveInterval) {
      return; // 静默跳过，不记录日志
    }

    // 🔧 防并发: 正在保存则跳过
    if (_isSaving) return;

    try {
      _isSaving = true;
      await _ensureCacheFile();
      if (_cacheFile == null) return;

      final cacheData = {
        'timestamp': now.toIso8601String(),
        'hopper': hopperData.map((k, v) => MapEntry(k, v.toJson())),
      };

      await _cacheFile!.writeAsString(jsonEncode(cacheData));
      _lastSaveTime = now; // 记录本次保存时间
    } catch (e, stack) {
      logger.error('保存缓存数据失败', e, stack);
    } finally {
      _isSaving = false;
    }
  }

  /// 加载缓存数据
  Future<CachedRealtimeData?> loadCache() async {
    try {
      await _ensureCacheFile();
      if (_cacheFile == null) return null;

      if (!await _cacheFile!.exists()) {
        logger.info('缓存文件不存在，将使用空数据');
        return null;
      }

      final content = await _cacheFile!.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // 解析 hopper 数据
      final hopperJson = json['hopper'] as Map<String, dynamic>? ?? {};
      final hopperData = hopperJson.map(
        (key, value) => MapEntry(key, HopperData.fromJson(value)),
      );

      return CachedRealtimeData(
        timestamp: DateTime.parse(json['timestamp']),
        hopperData: hopperData,
      );
    } catch (e, stack) {
      logger.error('加载缓存数据失败', e, stack);
      // 如果缓存文件损坏，建议删除
      try {
        if (_cacheFile != null && await _cacheFile!.exists()) {
          await _cacheFile!.delete();
          logger.warning('已删除损坏的缓存文件');
        }
      } catch (_) {}
      return null;
    }
  }
}

/// 缓存数据对象
class CachedRealtimeData {
  final DateTime timestamp;
  final Map<String, HopperData> hopperData;

  CachedRealtimeData({
    required this.timestamp,
    required this.hopperData,
  });
  
  bool get hasData => hopperData.isNotEmpty;
}
