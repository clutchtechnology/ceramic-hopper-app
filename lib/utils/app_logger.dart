import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// 应用日志系统 - 用于追踪崩溃和异常
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  File? _logFile;
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
  final _fileNameFormat = DateFormat('yyyy-MM-dd');
  bool _initialized = false;

  // 🔧 新增: 心跳定时器
  Timer? _heartbeatTimer;
  int _heartbeatCount = 0;
  DateTime? _startTime;

  /// 初始化日志系统
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _startTime = DateTime.now();

      // 获取日志目录
      final Directory logDir = await _getLogDirectory();

      // 创建日志文件（每天一个文件）
      final String fileName =
          'app_log_${_fileNameFormat.format(DateTime.now())}.log';
      _logFile = File('${logDir.path}${Platform.pathSeparator}$fileName');

      // 确保文件存在
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }

      _initialized = true;

      // 记录启动信息
      await _writeLog('INFO', '========================================');
      await _writeLog('INFO', 'APP STARTED');
      await _writeLog('INFO', 'Version: 1.0.0');
      await _writeLog('INFO',
          'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      await _writeLog('INFO', 'Log file: ${_logFile!.path}');
      await _writeLog('INFO', '========================================');

      // 清理旧日志（保留最近7天）
      await _cleanOldLogs(logDir, 7);

      // 🔧 启动心跳监控（每60秒记录一次）
      _startHeartbeat();
    } catch (e) {
      debugPrint('[AppLogger] 初始化失败: $e');
    }
  }

  /// 🔧 心跳监控：每12小时记录一次，减少日志噪音
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(hours: 12), (timer) async {
      try {
        _heartbeatCount++;
        final uptime = DateTime.now().difference(_startTime!);
        final hours = uptime.inHours;
        final minutes = uptime.inMinutes % 60;

        await _writeLog(
            'HEARTBEAT', '应用运行中 #$_heartbeatCount | 已运行: ${hours}h${minutes}m');
      } catch (e) {
        // 心跳异常不应该中断定时器
        debugPrint('[AppLogger] 心跳记录异常: $e');
      }
    });
  }

  /// 获取日志目录
  Future<Directory> _getLogDirectory() async {
    Directory logDir;

    if (Platform.isWindows) {
      // Windows: 使用应用程序所在目录的 data/logs
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent;
      logDir = Directory(
          '${exeDir.path}${Platform.pathSeparator}data${Platform.pathSeparator}logs');
    } else {
      // 其他平台: 使用应用文档目录
      final appDocDir = await getApplicationDocumentsDirectory();
      logDir = Directory('${appDocDir.path}${Platform.pathSeparator}logs');
    }

    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    return logDir;
  }

  /// 清理旧日志文件
  Future<void> _cleanOldLogs(Directory logDir, int daysToKeep) async {
    try {
      final now = DateTime.now();
      final files = logDir.listSync();

      for (var file in files) {
        if (file is File && file.path.endsWith('.log')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified).inDays;

          if (age > daysToKeep) {
            await file.delete();
            debugPrint('[AppLogger] 删除旧日志: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('[AppLogger] 清理旧日志失败: $e');
    }
  }

  /// 写入日志
  Future<void> _writeLog(String level, String message) async {
    if (!_initialized || _logFile == null) return;

    // 🔧 发行版本只记录错误级别：ERROR, FATAL
    // 排除所有其他日志：INFO, NETWORK, MEMORY, ACTION, LIFECYCLE, WARNING, HEARTBEAT
    if (!kDebugMode) {
      const allowedLevels = {'ERROR', 'FATAL'};
      if (!allowedLevels.contains(level)) {
        return;
      }
    }

    try {
      final timestamp = _dateFormat.format(DateTime.now());
      final logEntry = '[$timestamp] [$level] $message\n';

      // 写入文件
      await _logFile!
          .writeAsString(logEntry, mode: FileMode.append, flush: true);

      // 同时输出到控制台
      debugPrint(logEntry.trim());
    } catch (e) {
      debugPrint('[AppLogger] 写入日志失败: $e');
    }
  }

  // ============ 公共日志方法 ============

  /// 信息日志
  Future<void> info(String message) async {
    await _writeLog('INFO', message);
  }

  /// 警告日志
  Future<void> warning(String message) async {
    await _writeLog('WARNING', message);
  }

  /// 错误日志
  Future<void> error(String message,
      [Object? error, StackTrace? stackTrace]) async {
    final errorMsg = StringBuffer(message);
    if (error != null) {
      errorMsg.write('\nError: $error');
    }
    if (stackTrace != null) {
      errorMsg.write('\nStackTrace:\n$stackTrace');
    }
    await _writeLog('ERROR', errorMsg.toString());
  }

  /// 严重错误日志
  Future<void> fatal(String message,
      [Object? error, StackTrace? stackTrace]) async {
    final errorMsg = StringBuffer('🔴 FATAL ERROR: $message');
    if (error != null) {
      errorMsg.write('\nError: $error');
    }
    if (stackTrace != null) {
      errorMsg.write('\nStackTrace:\n$stackTrace');
    }
    await _writeLog('FATAL', errorMsg.toString());
  }

  /// 网络请求日志
  Future<void> network(String method, String url,
      {int? statusCode, String? error}) async {
    final msg = StringBuffer('$method $url');
    if (statusCode != null) {
      msg.write(' → $statusCode');
    }
    if (error != null) {
      msg.write(' [ERROR: $error]');
    }
    await _writeLog('NETWORK', msg.toString());
  }

  /// 内存使用日志
  Future<void> memory(String context, int usedMB, int totalMB) async {
    final percent = (usedMB / totalMB * 100).toStringAsFixed(1);
    await _writeLog('MEMORY',
        '$context - Used: ${usedMB}MB / Total: ${totalMB}MB ($percent%)');
  }

  /// 生命周期日志
  Future<void> lifecycle(String event) async {
    await _writeLog('LIFECYCLE', event);
  }

  /// 用户操作日志
  Future<void> userAction(String action) async {
    await _writeLog('ACTION', action);
  }

  /// 获取当前日志文件路径
  String? get logFilePath => _logFile?.path;

  /// 关闭日志系统
  Future<void> close() async {
    if (_initialized) {
      // 🔧 停止心跳定时器
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;

      final uptime = DateTime.now().difference(_startTime!);
      final hours = uptime.inHours;
      final minutes = uptime.inMinutes % 60;

      await _writeLog('INFO', '========================================');
      await _writeLog('INFO', 'APP CLOSED NORMALLY');
      await _writeLog('INFO', '总运行时长: ${hours}小时${minutes}分钟');
      await _writeLog('INFO', '心跳次数: $_heartbeatCount');
      await _writeLog('INFO', '========================================');
      _initialized = false;
    }
  }
}

/// 全局日志实例
final logger = AppLogger();
